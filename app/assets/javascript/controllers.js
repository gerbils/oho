import { application } from "./controllers/application.js"

import ChartsController from "./controllers/charts_controller"
application.register("charts", ChartsController)

import DarkLightController from "./controllers/dark_light_controller"
application.register("dark-light-toggle", DarkLightController)

import FileUploadController from "./controllers/file_upload_controller"
application.register("file-upload", FileUploadController)

import PopoverController from "./controllers/popover_controller"
application.register("popover", PopoverController)
