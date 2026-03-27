"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onOrderStatusChanged = exports.onOrderCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
async function sendNotification(token, title, body, data = {}) {
    if (!token)
        return;
    try {
        await messaging.send({
            token,
            notification: { title, body },
            data,
            android: { notification: { channelId: 'foodie_orders', priority: 'high', sound: 'default' } },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        });
        functions.logger.info(`Notification sent to ${token.slice(0, 10)}...`);
    }
    catch (e) {
        functions.logger.error('sendNotification failed:', e);
    }
}
async function getAdminTokens() {
    const snap = await db.collection('users').where('isAdmin', '==', true).get();
    return snap.docs.map(d => d.data().fcmToken).filter(t => !!t);
}
exports.onOrderCreated = functions.firestore
    .document('orders/{orderId}')
    .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;
    functions.logger.info(`New order: ${orderId}`);
    const adminTokens = await getAdminTokens();
    if (adminTokens.length === 0)
        return functions.logger.warn('No admin tokens found.');
    const title = '🛒 New Order Received!';
    const body = `${order.customerName || 'A customer'} placed ${order.orderNumber} — R${Number(order.total).toFixed(2)}`;
    await Promise.all(adminTokens.map(token => sendNotification(token, title, body, {
        type: 'new_order',
        orderId,
        orderNumber: order.orderNumber ?? '',
    })));
});
exports.onOrderStatusChanged = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;
    if (!before || !after) {
        functions.logger.warn('Missing before/after data');
        return;
    }
    functions.logger.info(`Order ${orderId}: ${before.status} → ${after.status}`);
    const userDoc = await db.collection('users').doc(after.userId).get();
    const customerToken = userDoc.data()?.fcmToken;
    if (!customerToken)
        return functions.logger.warn(`No FCM token for user ${after.userId}`);
    const messages = {
        confirmed: { title: '✅ Order Confirmed!', body: `${after.orderNumber} has been confirmed by the restaurant.` },
        preparing: { title: '👨‍🍳 Being Prepared', body: `${after.orderNumber} is being prepared in the kitchen.` },
        onTheWay: { title: '🛵 On the Way!', body: `${after.orderNumber} is on its way to you. Get ready!` },
        delivered: { title: '🎉 Order Delivered!', body: `${after.orderNumber} has been delivered. Enjoy your meal!` },
        cancelled: { title: '❌ Order Cancelled', body: `${after.orderNumber} has been cancelled. Contact us if needed.` },
    };
    const msg = messages[after.status];
    if (!msg)
        return;
    await sendNotification(customerToken, msg.title, msg.body, {
        type: 'order_status',
        orderId,
        status: after.status,
        orderNumber: after.orderNumber ?? '',
    });
});
