/**
 * Created by zh99998 on 2017/6/1.
 */
import * as Raven from 'raven-js';
import { ErrorHandler } from '@angular/core';

Raven
    .config('https://2c5fa0d0f13c43b5b96346f4eff2ea60@sentry.io/174769')
    .install();

export class RavenErrorHandler implements ErrorHandler {
    handleError(err: any): void {
        Raven.captureException(err.originalError || err);
    }
}