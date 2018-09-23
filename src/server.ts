import Raven from "raven";
import express from "express";
import * as path from "path";
import { appendFile } from "fs";
import MyError from "./error";

const packageJson = require("../package.json");
const SENTRY_DSN = process.env.SENTRY_DSN;

const root = __dirname || process.cwd();

Raven.config(SENTRY_DSN, {
  // the rest of configuration
  release: packageJson.version,
  dataCallback: function(data) {
    var stacktrace = data.exception && data.exception[0].stacktrace;

    if (stacktrace && stacktrace.frames) {
      stacktrace.frames.forEach(function(frame: any) {
        if (frame.filename.startsWith("/")) {
          frame.filename = "app:///" + path.relative(root, frame.filename);
        }
      });
    }

    return data;
  }
}).install();

const app = express();

app.use(Raven.requestHandler());
app.get("/", function() {
  const myError = new MyError();

  myError.boom();
});
app.use(Raven.errorHandler());
app.listen(3000);
