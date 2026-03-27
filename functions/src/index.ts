import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

async function sendNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data,
      android: { notification: { channelId: 'foodie_orders', priority: 'high', sound: 'default' } },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    });
    functions.logger.info(`Notification sent to ${token.slice(0, 10)}...`);
  } catch (e) {
    functions.logger.error('sendNotification failed:', e);
  }
}

async function getAdminTokens(): Promise<string[]> {
  const snap = await db.collection('users').where('isAdmin', '==', true).get();
  return snap.docs.map(d => d.data().fcmToken as string).filter(t => !!t);
}

export const onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;
    functions.logger.info(`New order: ${orderId}`);
    const adminTokens = await getAdminTokens();
    if (adminTokens.length === 0) return functions.logger.warn('No admin tokens found.');
    const title = '🛒 New Order Received!';
    const body = `${order.customerName || 'A customer'} placed ${order.orderNumber} — R${Number(order.total).toFixed(2)}`;
    await Promise.all(adminTokens.map(token => sendNotification(token, title, body, {
      type: 'new_order',
      orderId,
      orderNumber: order.orderNumber ?? '',
    })));
  });

export const onOrderStatusChanged = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change: functions.Change<FirebaseFirestore.DocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
const after = change.after.data();
    const orderId = context.params.orderId;
    if (!before || !after) {
  functions.logger.warn('Missing before/after data');
  return;
}
    functions.logger.info(`Order ${orderId}: ${before.status} → ${after.status}`);
    const userDoc = await db.collection('users').doc(after.userId).get();
    const customerToken = userDoc.data()?.fcmToken as string | undefined;
    if (!customerToken) return functions.logger.warn(`No FCM token for user ${after.userId}`);
    const messages: Record<string, { title: string; body: string }> = {
      confirmed: { title: '✅ Order Confirmed!', body: `${after.orderNumber} has been confirmed by the restaurant.` },
      preparing: { title: '👨‍🍳 Being Prepared', body: `${after.orderNumber} is being prepared in the kitchen.` },
      onTheWay: { title: '🛵 On the Way!', body: `${after.orderNumber} is on its way to you. Get ready!` },
      delivered: { title: '🎉 Order Delivered!', body: `${after.orderNumber} has been delivered. Enjoy your meal!` },
      cancelled: { title: '❌ Order Cancelled', body: `${after.orderNumber} has been cancelled. Contact us if needed.` },
    };
    const msg = messages[after.status as string];
    if (!msg) return;
    await sendNotification(customerToken, msg.title, msg.body, {
      type: 'order_status',
      orderId,
      status: after.status,
      orderNumber: after.orderNumber ?? '',
    });
  });