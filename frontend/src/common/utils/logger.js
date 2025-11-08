/**
 * Production-ready logging utility for BrightPlanet Ventures
 * Provides structured logging with different levels and proper error handling
 */

const LOG_LEVELS = {
  ERROR: 0,
  WARN: 1,
  INFO: 2,
  DEBUG: 3
};

const LOG_LEVEL_NAMES = {
  0: 'ERROR',
  1: 'WARN',
  2: 'INFO',
  3: 'DEBUG'
};

class Logger {
  constructor() {
    // Set log level based on environment
    this.logLevel = process.env.NODE_ENV === 'production' ? LOG_LEVELS.WARN : LOG_LEVELS.DEBUG;
    this.enableConsole = process.env.NODE_ENV !== 'production';
  }

  formatMessage(level, message, context = {}) {
    const timestamp = new Date().toISOString();
    const levelName = LOG_LEVEL_NAMES[level];
    
    return {
      timestamp,
      level: levelName,
      message,
      context,
      userAgent: navigator.userAgent,
      url: window.location.href
    };
  }

  log(level, message, context = {}) {
    if (level > this.logLevel) return;

    const logEntry = this.formatMessage(level, message, context);
    
    // Console logging for development
    if (this.enableConsole) {
      const emoji = this.getEmoji(level);
      const style = this.getStyle(level);
      
      console.log(
        `%c${emoji} [${logEntry.level}] ${logEntry.message}`,
        style,
        context
      );
    }

    // In production, you could send logs to a service like LogRocket, Sentry, etc.
    if (process.env.NODE_ENV === 'production' && level <= LOG_LEVELS.WARN) {
      this.sendToLoggingService(logEntry);
    }
  }

  getEmoji(level) {
    switch (level) {
      case LOG_LEVELS.ERROR: return '🚨';
      case LOG_LEVELS.WARN: return '⚠️';
      case LOG_LEVELS.INFO: return 'ℹ️';
      case LOG_LEVELS.DEBUG: return '🔍';
      default: return '📝';
    }
  }

  getStyle(level) {
    switch (level) {
      case LOG_LEVELS.ERROR: return 'color: #ef4444; font-weight: bold;';
      case LOG_LEVELS.WARN: return 'color: #f59e0b; font-weight: bold;';
      case LOG_LEVELS.INFO: return 'color: #3b82f6; font-weight: bold;';
      case LOG_LEVELS.DEBUG: return 'color: #6b7280; font-weight: normal;';
      default: return 'color: #374151;';
    }
  }

  sendToLoggingService(logEntry) {
    // Placeholder for production logging service
    // You could integrate with services like:
    // - Sentry: Sentry.captureMessage(logEntry.message, logEntry.level);
    // - LogRocket: LogRocket.log(logEntry);
    // - Custom API endpoint
    
    if (logEntry.level === 'ERROR') {
      // For errors, you might want to send immediately
      fetch('/api/logs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(logEntry)
      }).catch(() => {
        // Silently fail if logging service is unavailable
      });
    }
  }

  error(message, context = {}) {
    this.log(LOG_LEVELS.ERROR, message, context);
  }

  warn(message, context = {}) {
    this.log(LOG_LEVELS.WARN, message, context);
  }

  info(message, context = {}) {
    this.log(LOG_LEVELS.INFO, message, context);
  }

  debug(message, context = {}) {
    this.log(LOG_LEVELS.DEBUG, message, context);
  }

  // Convenience methods for common use cases
  apiCall(method, url, data = null) {
    this.debug(`API ${method.toUpperCase()}: ${url}`, { data });
  }

  apiResponse(method, url, status, data = null) {
    const level = status >= 400 ? LOG_LEVELS.ERROR : LOG_LEVELS.DEBUG;
    this.log(level, `API ${method.toUpperCase()} ${url} - ${status}`, { data });
  }

  userAction(action, context = {}) {
    this.info(`User Action: ${action}`, context);
  }

  dataLoad(entity, count, duration = null) {
    this.debug(`Data Loaded: ${entity} (${count} items)`, { count, duration });
  }

  performance(operation, duration) {
    const level = duration > 1000 ? LOG_LEVELS.WARN : LOG_LEVELS.DEBUG;
    this.log(level, `Performance: ${operation} took ${duration}ms`, { duration });
  }

  success(message, context = {}) {
    this.log(LOG_LEVELS.INFO, `✅ ${message}`, context);
  }
}

// Create singleton instance
const logger = new Logger();

export default logger;

// Export convenience methods for easier usage
export const { error, warn, info, debug, apiCall, apiResponse, userAction, dataLoad, performance, success } = logger;
