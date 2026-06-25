import { pino, type Logger } from "pino";

import type { AppConfig } from "../../config/app-config.js";

export type AppLogger = Logger;

export function createLogger(config: AppConfig): AppLogger {
  return pino({
    name: config.appName,
    level: config.logLevel,
  });
}
