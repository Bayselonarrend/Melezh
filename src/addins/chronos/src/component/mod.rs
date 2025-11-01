mod scheduler;

use std::sync::{Arc, Mutex};
use addin1c::{name, Variant};
use crossbeam_channel::Sender;
use serde_json::{json, Value};
use crate::component::scheduler::CronScheduler;
use crate::core::getset;

// МЕТОДЫ КОМПОНЕНТЫ -------------------------------------------------------------------------------

pub const METHODS: &[&[u16]] = &[
    name!("Init"),
    name!("NextEvent"),
    name!("AddJob"),
    name!("RemoveJob"),
    name!("UpdateJob"),
    name!("DisableJob"),
    name!("EnableJob"),
    name!("GetJobList")
];

pub fn get_params_amount(num: usize) -> usize {
    match num {
        0 => 1, // Init
        1 => 0, // NextEvent
        2 => 2, // AddJob (name, schedule)
        3 => 1, // RemoveJob (name)
        4 => 2, // UpdateJob (name, new_schedule)
        5 => 1, // DisableJob (name)
        6 => 1, // EnableJob (name)
        7 => 0, // GetJobList
        _ => 0,
    }
}

// Соответствие функций Rust функциям компоненты
// Вызовы должны быть обернуты в Box::new
pub fn cal_func(obj: &mut AddIn, num: usize, params: &mut [Variant]) -> Box<dyn getset::ValueType> {
    match num {
        0 => {
            let schedule = params[0].get_string().unwrap_or(String::new());
            Box::new(obj.init_schedule(schedule))
        },
        1 => {
            Box::new(obj.next_event())
        },
        2 => {
            let name = params[0].get_string().unwrap_or(String::new());
            let schedule = params[1].get_string().unwrap_or(String::new());
            Box::new(obj.add_job(&name, &schedule))
        },
        3 => {
            let name = params[0].get_string().unwrap_or(String::new());
            Box::new(obj.remove_job(&name))
        },
        4 => {
            let name = params[0].get_string().unwrap_or(String::new());
            let new_schedule = params[1].get_string().unwrap_or(String::new());
            Box::new(obj.update_job(&name, &new_schedule))
        },
        5 => {
            let name = params[0].get_string().unwrap_or(String::new());
            Box::new(obj.disable_job(&name))
        },
        6 => {
            let name = params[0].get_string().unwrap_or(String::new());
            Box::new(obj.enable_job(&name))
        },
        7 => {
            Box::new(obj.get_job_list())
        },
        _ => Box::new(false)
    }
}

// -------------------------------------------------------------------------------------------------

// ПОЛЯ КОМПОНЕНТЫ ---------------------------------------------------------------------------------

// Синонимы
pub const PROPS: &[&[u16]] = &[];

pub struct AddIn {
    scheduler: Option<Arc<Mutex<CronScheduler>>>,
    event_sender: Option<Sender<String>>,
}

impl AddIn {
    pub fn new() -> Self {
        AddIn {
            scheduler: None,
            event_sender: None,
        }
    }

    pub fn init_schedule(&mut self, schedule: String) -> String {
        let schedule_data = if schedule.trim().is_empty() {
            Vec::new()
        } else {
            let data = match serde_json::from_str(schedule.as_str()) {
                Ok(v) => v,
                Err(e) => return format_json_error(&e.to_string())
            };

            match value_to_vec(data) {
                Ok(v) => v,
                Err(e) => return format_json_error(&e.to_string())
            }
        };

        let scheduler = match CronScheduler::new(schedule_data) {
            Ok(s) => s,
            Err(e) => return format_json_error(&e.to_string())
        };

        let event_sender = scheduler.get_event_sender_clone();

        self.event_sender = Some(event_sender);
        self.scheduler = Some(Arc::new(Mutex::new(scheduler)));
        json!({"result": true}).to_string()
    }

    pub fn next_event(&mut self) -> String {

        match &self.scheduler {
            Some(scheduler) => {

                let scheduler_ref = scheduler.clone();

                let s = match scheduler_ref.lock(){
                    Ok(s) => s,
                    Err(e) => return format_json_error(&e.to_string())
                };
                s.next_event().unwrap_or(String::from(""))
            },
            None => format_json_error("Init scheduler first")
        }
    }

    pub fn add_job(&mut self, name: &str, schedule: &str) -> String {

        match &self.scheduler {
            Some(scheduler) => {

                if let Some(sender) = &self.event_sender {
                    let _ = sender.send(String::new());
                }

                let sch = match scheduler.lock(){
                    Ok(s) => s,
                    Err(e) => return format_json_error(&e.to_string())
                };
                match sch.add_job(name, schedule) {
                    Ok(_) => json!({"result": true}).to_string(),
                    Err(e) => format_json_error(&e.to_string())
                }
            },
            None => format_json_error("Init scheduler first")
        }
    }

    pub fn remove_job(&mut self, name: &str) -> String {

        match self.scheduler.as_mut() {
            Some(s) => {

                if let Some(sender) = &self.event_sender {
                    let _ = sender.send(String::new());
                }

                let sch = match s.lock(){
                    Ok(s) => s,
                    Err(e) => return format_json_error(&e.to_string())
                };
                match sch.remove_job(name) {
                    Ok(_) => json!({"result": true}).to_string(),
                    Err(e) => format_json_error(&e.to_string())
                }
            },
            None => format_json_error("Init scheduler first")
        }
    }

    pub fn update_job(&mut self, name: &str, new_schedule: &str) -> String {

        match self.scheduler.as_mut() {
            Some(s) => {

                if let Some(sender) = &self.event_sender {
                    let _ = sender.send(String::new());
                }

                let sch = match s.lock(){
                    Ok(s) => s,
                    Err(e) => return format_json_error(&e.to_string())
                };
                match sch.update_job_schedule(name, new_schedule) {
                    Ok(_) => json!({"result": true}).to_string(),
                    Err(e) => format_json_error(&e.to_string())
                }
            },
            None => format_json_error("Init scheduler first")
        }
    }

    pub fn disable_job(&mut self, name: &str) -> String {

        match self.scheduler.as_mut() {
            Some(s) => {

                if let Some(sender) = &self.event_sender {
                    let _ = sender.send(String::new());
                }

                let sch = match s.lock(){
                    Ok(s) => s,
                    Err(e) => return format_json_error(&e.to_string())
                };

                match sch.disable_job(name) {
                    Ok(_) => json!({"result": true}).to_string(),
                    Err(e) => format_json_error(&e.to_string())
                }
            },
            None => format_json_error("Init scheduler first")
        }
    }

    pub fn enable_job(&mut self, name: &str) -> String {

        match self.scheduler.as_mut() {
            Some(s) => {

                if let Some(sender) = &self.event_sender {
                    let _ = sender.send(String::new());
                }

                let sch = match s.lock(){
                    Ok(s) => s,
                    Err(e) => return format_json_error(&e.to_string())
                };

                match sch.enable_job(name) {
                    Ok(_) => json!({"result": true}).to_string(),
                    Err(e) => format_json_error(&e.to_string())
                }
            },
            None => format_json_error("Init scheduler first")
        }
    }

    pub fn get_job_list(&mut self) -> String {

        match self.scheduler.as_mut() {
            Some(s) => {

                if let Some(sender) = &self.event_sender {
                    let _ = sender.send(String::new());
                }

                let sch = match s.lock(){
                    Ok(s) => s,
                    Err(e) => return format_json_error(&e.to_string())
                };

                match sch.get_job_list() {
                    Ok(jobs) => json!({"result": true, "jobs": jobs}).to_string(),
                    Err(e) => format_json_error(&e.to_string())
                }
            },
            None => format_json_error("Init scheduler first")
        }
    }

    pub fn get_field_ptr(&self, index: usize) -> *const dyn getset::ValueType {
        match index {
            _ => panic!("Index out of bounds"),
        }
    }

    pub fn get_field_ptr_mut(&mut self, index: usize) -> *mut dyn getset::ValueType {
        self.get_field_ptr(index) as *mut _
    }
}

// -------------------------------------------------------------------------------------------------

// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ -------------------------------------------------------------------------

pub fn format_json_error(error: &str) -> String {
    json!({"result": false, "error": error}).to_string()
}

pub fn value_to_vec(value: Value) -> Result<Vec<(String, String)>, String> {
    let mut result = Vec::new();

    if let Value::Object(obj) = value {
        for (name, schedule_value) in obj {
            // Получаем строковое значение
            let schedule_str = match schedule_value {
                Value::String(s) => s,
                Value::Number(n) => n.to_string(), // Если число, конвертируем в строку
                _ => return Err(format!("Invalid schedule type for key '{}': expected string or number", name))
            };

            // Очищаем строку от лишних пробелов и символов
            let cleaned_schedule = schedule_str
                .trim() // Убираем пробелы в начале и конце
                .replace('\n', "") // Убираем переносы строк
                .replace('^', "") // Убираем символы ^
                .replace("  ", " ") // Заменяем двойные пробелы на одинарные
                .trim() // Еще раз убираем пробелы по краям
                .to_string();

            // Проверяем, что строка не пустая после очистки
            if cleaned_schedule.is_empty() {
                return Err(format!("Empty schedule after cleaning for key '{}'", name));
            }

            result.push((name, cleaned_schedule));
        }
    } else {
        return Err("Expected JSON object".to_string());
    }

    // Проверяем, что есть хотя бы одно событие
    if result.is_empty() {
        return Err("No events found in JSON object".to_string());
    }

    Ok(result)
}

// УНИЧТОЖЕНИЕ ОБЪЕКТА -----------------------------------------------------------------------------

// Обработка удаления объекта
impl Drop for AddIn {
    fn drop(&mut self) {
        // Планировщик автоматически завершит все задачи при drop
    }
}