const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize the Firebase Admin SDK. 
admin.initializeApp();

exports.onNotificationCreated = functions.firestore
  .document('users/{userId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const userId = context.params.userId;

    // We don't want to send a push notification if they've already read it
    if (notificationData.isRead) {
      return null;
    }

    try {
      // 1. Get the user's FCM tokens from their user document
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.log(`User \${userId} does not exist`);
        return null;
      }

      const userData = userDoc.data();
      const fcmTokens = userData.fcmTokens;

      if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
        console.log(`User \${userId} has no FCM tokens registered.`);
        return null;
      }

      // 1b. Check Notification Settings
      const settingsDoc = await admin.firestore().collection('users').doc(userId).collection('settings').doc('notifications').get();
      let settings = {
        expenseAlerts: true,
        settlementAlerts: true,
        chatAlerts: true,
        memberAlerts: true,
        groupAlerts: true,
        weeklySummaryAlerts: false
      };
      if (settingsDoc.exists) {
        settings = { ...settings, ...settingsDoc.data() };
      }

      const type = notificationData.type || 'general';
      
      // Map event types to settings flags
      if (type.startsWith('expense') && !settings.expenseAlerts) return null;
      if (type.startsWith('settlement') && !settings.settlementAlerts) return null;
      if (type.startsWith('chat') && !settings.chatAlerts) return null;
      if (type.startsWith('member') && !settings.memberAlerts) return null;
      if (type.startsWith('group') && !settings.groupAlerts) return null;

      // 2. Prepare the Notification Payload
      // Note: We use the newer sendToDevice/Multicast API equivalent structure
      const payload = {
        notification: {
          title: notificationData.title || 'SplitNest',
          body: notificationData.description || 'You have a new notification.',
        },
        data: {
          type: type,
          relatedItemId: notificationData.relatedItemId || '',
          groupId: notificationData.groupId || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
      };

      // 3. Send the message to all devices the user is logged into
      const response = await admin.messaging().sendToDevice(fcmTokens, payload);
      
      // 4. (Optional) Cleanup invalid tokens
      const tokensToRemove = [];
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          console.error('Failure sending notification to', fcmTokens[index], error);
          if (
            error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered'
          ) {
            tokensToRemove.push(fcmTokens[index]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        await admin.firestore().collection('users').doc(userId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
        });
      }

      return null;
    } catch (error) {
      console.error('Error sending push notification:', error);
      return null;
    }
  });
