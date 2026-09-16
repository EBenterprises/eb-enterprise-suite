const Order = require('../models/order.model');

class OrderService {
  async createOrder(orderData) {
    const order = new Order(orderData);
    await order.save();
    return order;
  }

  async getOrders(filter = {}, sort = { createdAt: -1 }) {
    return await Order.find(filter).sort(sort).populate('requester', 'name email');
  }

  async updateOrderStatus(orderId, updateData) {
    return await Order.findByIdAndUpdate(orderId, updateData, { new: true })
      .populate('requester', 'name email');
  }
}

module.exports = new OrderService();
