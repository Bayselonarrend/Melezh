![image](/media/cover_s.png)



# Melezh

[![OpenIntegrations](media/addon.svg)](https://github.com/Bayselonarrend/OpenIntegrations)
[![OneScript](media/oscript.svg)](https://github.com/EvilBeaver/OneScript)


Server version of the Open Integrations Package, providing a unified configurable HTTP API for accessing its libraries and custom `.os` scripts (extensions), with support for default values, a web console, and built-in logging of incoming requests

## How It Works

This server is based on `oint` - the console application of the [Open Integrations Package](https://github.com/bayselonarrend/OpenIntegrations), and allows remote invocation of its methods via HTTP requests from anywhere, just as it would happen in the console on a local machine. Melezh uses the Kestrel server built into OneScript to receive HTTP requests, which are then interpreted into `oint` commands (or commands of extension modules) for further execution.

The solution features a flexible configuration system that allows defining restrictions for the list of available commands and methods, as well as setting default parameter values for command execution. This enables both reducing the amount of data transmitted and hiding sensitive data from the client side when necessary


## Example

This example creates a new project file with a GET request handler configuration for the `SendTextMessage` function from the Telegram library. It also sets a default value for the `token` parameter with no overwrite capability ("strict")

```powershell

melezh CreateProject      --path R:\test_proj.melezh
melezh AddRequestsHandler --proj R:\test_proj.melezh --lib telegram --func SendTextMessage --method GET
melezh SetHandlerArgument --proj R:\test_proj.melezh --handler 42281f11b --arg token --value "***" --strict true
melezh RunProject         --proj R:\test_proj.melezh --port 7788

```

The handler will be available at `localhost:7788/42281f11b`, where `42281f11b` is the identifier obtained when calling `AddRequestHandler`. This identifier serves both as the handler's configuration key and as the URL endpoint for requests

Request example for sending a text message:

```url
http://localhost:7788/42281f11b?chat=123123123&text="Hello world!"
```

As you may have noticed, we're not passing the token as it's set by default

## Web UI

In addition to the CLI interface, for easier interactive configuration and management, you can use the web console built into Melezh:

![chrome_aDGtJZRrD8](https://github.com/user-attachments/assets/25762182-19b5-446c-8135-e87339cd7b02)

*On the recording: logging into the console, adding a new handler for creating a Bitrix24 news item with two default parameters specified, disabling two handlers, viewing details of one of the recent events, reviewing all logs for one of today’s handlers*

<br>

**The web console allows you to:**
- Monitor the server’s latest events
- Add, modify, and delete handlers, or adjust default parameter sets
- Temporarily enable or disable handlers
- View detailed logs for each processed request
- Modify server settings

If you’re just getting started with Melezh, this mode is recommended. Access the web console at `localhost:<your_port>/ui` after creating and launching the project

## Installation

<img src="/media/box_s.png" align="left" width="200">

<br>

Melezh can be installed using a Windows installer, rpm or deb package, OneScript package, or within a Docker container. The required files are available in the releases of this repository <br><hr>
*Learn more about the installation method and process on the [documentation page](https://en.openintegrations.org/docs/Addons/Melezh/Start/Installation)*

<br>

## Documentation

<img src="https://github.com/user-attachments/assets/44614ade-d524-475b-ad5e-f4790994e836" align="left" width="200">

<br>

More information about console commands, logging, Web UI capabilities, and working with Melezh in general can be found in the [online documentation](https://en.openintegrations.dev/docs/Addons/Melezh).  It is hosted on the same portal as the documentation for the main project - Open Integration Package, where you can also find information about methods available as handler functions within Melezh. The documentation is available in two language versions - Russian and English