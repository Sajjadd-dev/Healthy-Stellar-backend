import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { NotificationsService, MAILER_SERVICE } from './services/notifications.service';
import { WsJwtMiddleware } from './middleware/ws-jwt.middleware';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationQueueService } from './services/notification-queue.service';
import { NotificationPreferencesService } from './services/notification-preferences.service';
import { NotificationPreferenceCenterService } from './services/notification-preference-center.service';
import { NotificationDigestTask } from './services/notification-digest.task';
import { OnChainEventListenerService } from './services/on-chain-event-listener.service';
import { NotificationTemplateService } from './services/notification-template.service';
import { NotificationOutboxService } from './services/notification-outbox.service';
import { NotificationPreference } from './entities/notification-preference.entity';
import { NotificationOutboxEntry } from './entities/notification-outbox.entity';
import { NotificationCategoryPreference } from './entities/notification-category-preference.entity';
import { NotificationPreferencesController } from './controllers/notification-preferences.controller';
import { EventListenerHealthIndicator } from './event-listener.health';
import { EventListenerUpGauge, MissedEventsTotalCounter } from './notifications.metrics';
import { AuthModule } from '../auth/auth.module';
import { I18nAppModule } from '../i18n/i18n.module';
import { PubSubModule } from '../pubsub/pubsub.module';

function buildMailerProvider() {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { MailerService } = require('@nestjs-modules/mailer');
    return {
      provide: MAILER_SERVICE,
      useExisting: MailerService,
    };
  } catch {
    return null;
  }
}

const mailerProvider = buildMailerProvider();

@Module({
  imports: [
    ConfigModule,
    AuthModule,
    I18nAppModule,
    PubSubModule,
    TypeOrmModule.forFeature([
      NotificationPreference,
      NotificationOutboxEntry,
      NotificationCategoryPreference,
    ]),
  ],
  controllers: [NotificationPreferencesController],
  providers: [
    NotificationsGateway,
    WsJwtMiddleware,
    NotificationsService,
    NotificationQueueService,
    NotificationPreferencesService,
    NotificationPreferenceCenterService,
    NotificationDigestTask,
    OnChainEventListenerService,
    NotificationTemplateService,
    NotificationOutboxService,
    EventListenerHealthIndicator,
    EventListenerUpGauge,
    MissedEventsTotalCounter,
    ...(mailerProvider ? [mailerProvider] : []),
  ],
  exports: [
    NotificationsService,
    NotificationPreferencesService,
    NotificationPreferenceCenterService,
    OnChainEventListenerService,
    NotificationTemplateService,
    NotificationOutboxService,
    EventListenerHealthIndicator,
  ],
})
export class NotificationsModule {}
