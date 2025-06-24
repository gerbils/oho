import { application } from "./controllers/application.js"

import ChartsController from "./controllers/charts_controller"
application.register("charts", ChartsController)

import FileUploadController from "./controllers/file_upload_controller"
application.register("file-upload", FileUploadController)
