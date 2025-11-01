use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use std::thread;

use cron::Schedule;
use crossbeam_channel::{unbounded, Receiver, Sender};
use std::str::FromStr;
use chrono::{DateTime, Utc};
use tokio::sync::{Mutex, RwLock};
use tokio::task::JoinHandle;
use tokio::time::sleep;

#[derive(Debug, Clone)]
pub struct CronEvent {
    pub name: String,
    pub schedule: Schedule,
}

// Состояние отдельной задачи
struct JobState {
    event: CronEvent,
    last_triggered: Option<DateTime<Utc>>,
    is_active: bool,
    task_handle: Option<JoinHandle<()>>,
}

// Основной планировщик с управлением задачами
pub struct CronScheduler {
    control_sender: Sender<JobControlMessage>,
    event_sender: Sender<String>,
    event_receiver: Receiver<String>,
    jobs: Arc<RwLock<HashMap<String, JobState>>>,
}

// Сообщения для управления задачами
enum JobControlMessage {
    AddJob(String, CronEvent),
    RemoveJob(String),
    UpdateJob(String, Schedule),
    DisableJob(String),
    EnableJob(String),
    Shutdown,
}

impl CronScheduler {
    pub fn new(events: Vec<(String, String)>) -> Result<Self, Box<dyn std::error::Error>> {
        let (event_sender, event_receiver) = unbounded();
        let (control_sender, control_receiver) = unbounded();

        let jobs = Arc::new(RwLock::new(HashMap::new()));

        let jobs_clone = Arc::clone(&jobs);
        let event_sender_clone = event_sender.clone();

        thread::spawn(move || {
            let rt = tokio::runtime::Builder::new_multi_thread()
                .enable_all()
                .build()
                .expect("Failed to create Tokio runtime");

            rt.block_on(Self::async_scheduler_process(
                jobs_clone,
                event_sender_clone,
                control_receiver,
            ));
        });

        let scheduler = Self {
            control_sender,
            event_sender,
            event_receiver,
            jobs,
        };

        for (name, schedule_str) in events {
            scheduler.add_job(&name, &schedule_str)?;
        }

        Ok(scheduler)
    }

    pub fn get_event_sender_clone(&self) -> Sender<String> {
        self.event_sender.clone() // Возвращаем клон отправителя
    }

    // Добавить новую задачу
    pub fn add_job(&self, name: &str, schedule_str: &str) -> Result<(), Box<dyn std::error::Error>> {
        let schedule = Schedule::from_str(schedule_str)?;
        let event = CronEvent {
            name: name.to_string(),
            schedule,
        };

        self.control_sender.send(JobControlMessage::AddJob(
            name.to_string(),
            event,
        ))?;

        Ok(())
    }

    // Удалить задачу
    pub fn remove_job(&self, name: &str) -> Result<(), Box<dyn std::error::Error>> {
        self.control_sender.send(JobControlMessage::RemoveJob(
            name.to_string(),
        ))?;
        Ok(())
    }

    // Обновить расписание задачи
    pub fn update_job_schedule(&self, name: &str, new_schedule_str: &str) -> Result<(), Box<dyn std::error::Error>> {
        let new_schedule = Schedule::from_str(new_schedule_str)?;
        self.control_sender.send(JobControlMessage::UpdateJob(
            name.to_string(),
            new_schedule,
        ))?;
        Ok(())
    }

    // Временно отключить задачу
    pub fn disable_job(&self, name: &str) -> Result<(), Box<dyn std::error::Error>> {
        self.control_sender.send(JobControlMessage::DisableJob(
            name.to_string(),
        ))?;
        Ok(())
    }

    // Включить задачу
    pub fn enable_job(&self, name: &str) -> Result<(), Box<dyn std::error::Error>> {
        self.control_sender.send(JobControlMessage::EnableJob(
            name.to_string(),
        ))?;
        Ok(())
    }

    // Получить список активных задач
    pub fn get_job_list(&self) -> Result<Vec<String>, Box<dyn std::error::Error>> {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()?;

        rt.block_on(async {
            let jobs = self.jobs.read().await;
            Ok(jobs.keys().cloned().collect())
        })
    }

    pub fn next_event(&self) -> Option<String> {
        self.event_receiver.recv().ok()
    }

    async fn async_scheduler_process(
        jobs: Arc<RwLock<HashMap<String, JobState>>>,
        event_sender: Sender<String>,
        control_receiver: Receiver<JobControlMessage>,
    ) {
        let event_queue = Arc::new(Mutex::new(Vec::new()));

        let queue_processor_event_sender = event_sender.clone();
        let queue_processor_queue = Arc::clone(&event_queue);
        tokio::spawn(async move {
            Self::queue_processor(queue_processor_queue, queue_processor_event_sender).await;
        });

        // Обрабатываем сообщения управления
        while let Ok(message) = control_receiver.recv() {
            match message {
                JobControlMessage::AddJob(name, event) => {
                    Self::start_job(
                        name.clone(),
                        event,
                        Arc::clone(&jobs),
                        Arc::clone(&event_queue),
                    ).await;
                }
                JobControlMessage::RemoveJob(name) => {
                    Self::stop_job(name, Arc::clone(&jobs)).await;
                }
                JobControlMessage::UpdateJob(name, new_schedule) => {
                    Self::update_job(name, new_schedule, Arc::clone(&jobs)).await;
                }
                JobControlMessage::DisableJob(name) => {
                    Self::set_job_active_status(name, false, Arc::clone(&jobs)).await;
                }
                JobControlMessage::EnableJob(name) => {
                    Self::set_job_active_status(name, true, Arc::clone(&jobs)).await;
                }
                JobControlMessage::Shutdown => {
                    break;
                }
            }
        }
    }

    async fn start_job(
        name: String,
        event: CronEvent,
        jobs: Arc<RwLock<HashMap<String, JobState>>>,
        event_queue: Arc<Mutex<Vec<String>>>,
    ) {

        let event_for_task = event.clone();
        let event_sender_clone = event_queue.clone();

        let task_handle = tokio::spawn(async move {
            Self::schedule_watcher(event_for_task, event_sender_clone).await;
        });

        let job_state = JobState {
            event, // оригинальный event используется здесь
            last_triggered: None,
            is_active: true,
            task_handle: Some(task_handle),
        };

        jobs.write().await.insert(name, job_state);
    }

    async fn stop_job(name: String, jobs: Arc<RwLock<HashMap<String, JobState>>>) {
        if let Some(mut job_state) = jobs.write().await.remove(&name) {
            if let Some(handle) = job_state.task_handle.take() {
                handle.abort();
            }
        }
    }

    async fn update_job(
        name: String,
        new_schedule: Schedule,
        jobs: Arc<RwLock<HashMap<String, JobState>>>,
    ) {
        if let Some(job_state) = jobs.write().await.get_mut(&name) {
            // Останавливаем старую задачу
            if let Some(handle) = job_state.task_handle.take() {
                handle.abort();
            }

            // Обновляем расписание
            job_state.event.schedule = new_schedule;
            job_state.last_triggered = None;
        }
    }

    async fn set_job_active_status(
        name: String,
        is_active: bool,
        jobs: Arc<RwLock<HashMap<String, JobState>>>,
    ) {
        if let Some(job_state) = jobs.write().await.get_mut(&name) {
            job_state.is_active = is_active;
        }
    }

    async fn schedule_watcher(
        event: CronEvent,
        event_queue: Arc<Mutex<Vec<String>>>,
    ) {
        let event_name = event.name.clone();
        let mut last_triggered = None::<DateTime<Utc>>;

        loop {
            let now: DateTime<Utc> = Utc::now();

            if let Some(upcoming) = event.schedule.after(&now).next() {
                let duration_until = upcoming - now;

                if duration_until.num_seconds() > 0 {
                    sleep(Duration::from_secs(duration_until.num_seconds() as u64)).await;

                    let should_trigger = match last_triggered {
                        Some(last) => {
                            let time_since_last = Utc::now() - last;
                            time_since_last.num_seconds() >= duration_until.num_seconds()
                        }
                        None => true,
                    };

                    if should_trigger {
                        event_queue.lock().await.push(event_name.clone());
                        last_triggered = Some(Utc::now());
                    }
                }
            }

            sleep(Duration::from_millis(100)).await;
        }
    }

    async fn queue_processor(
        event_queue: Arc<Mutex<Vec<String>>>,
        event_sender: Sender<String>,
    ) {
        loop {
            sleep(Duration::from_millis(50)).await;

            let events_to_send = {
                let mut queue = event_queue.lock().await;
                queue.drain(..).collect::<Vec<_>>()
            };

            for event_name in events_to_send {
                if event_sender.send(event_name).is_err() {
                    break;
                }
            }
        }
    }
}

impl Drop for CronScheduler {
    fn drop(&mut self) {
        let _ = self.control_sender.send(JobControlMessage::Shutdown);
    }
}