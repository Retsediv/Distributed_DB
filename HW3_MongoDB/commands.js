// 0 Очистити все
db.items.deleteMany({});


// 1 Створіть декілька товарів з різним набором властивостей Phone/TV/Smart/Watch/...
db.items.insertMany([
  { 
    "category": "Phone", 
    "model": "iPhone 6", 
    "producer": "Apple", 
    "price": 600 
  },
  { 
    "category": "Phone", 
    "model": "Galaxy S8", 
    "producer": "Samsung", 
    "price": 500 
  },
  { 
    "category": "TV", 
    "model": "Bravia X900", 
    "producer": "Sony", 
    "price": 1200,
    "screenSize": 55,
    "smartTV": true
  },
  { 
    "category": "Smart Watch", 
    "model": "Apple Watch Series 3", 
    "producer": "Apple", 
    "price": 300,
    "waterResistant": true,
    "GPS": true
  },
  { 
    "category": "Laptop", 
    "model": "XPS 13", 
    "producer": "Dell", 
    "price": 1000,
    "RAM": "8GB",
    "storage": "256GB"
  }
]);

// 2 Напишіть запит, який виводіть усі товари (відображення у JSON)
db.items.find().pretty();

// 3 Підрахуйте скільки товарів у певної категорії
db.items.find({ category: "Phone" }).count();

// 4 Підрахуйте скільки є різних категорій товарів
db.items.distinct("category").length;

// 5 Виведіть список всіх виробників товарів без повторів
db.items.distinct("producer");

// 6 Напишіть запити, які вибирають товари за різними критеріям і їх сукупності:
// a) категорія та ціна (в проміжку) - конструкція $and
db.items.find({
  $and: [
    { category: "Phone" },
    { price: { $gte: 500, $lte: 700 } }
  ]
});

// b) модель чи одна чи інша - конструкція $or
db.items.find({
  $or: [
    { model: "iPhone 6" },
    { model: "Galaxy S8" }
  ]
});

// c) виробники з переліку - конструкція $in
db.items.find({
  producer: { $in: ["Samsung", "Sony"] }
});

// 7 Оновить певні товари, змінивши існуючі значення і додайте нові властивості
// (характеристики) усім товарам за певним критерієм
db.items.updateMany(
  { category: "Phone" },
  {
    $inc: { price: -50 },
    $set: { discounted: true }
  }
);

db.items.find().pretty();


// 8 Знайдіть товари у яких є (присутнє поле) певні властивості
db.items.find({ screenSize: { $exists: true } });


// 9 Для знайдених товарів збільшіть їх вартість на певну суму
db.items.updateMany(
  { screenSize: { $exists: true } },
  { $inc: { price: 100 } }
);

db.items.find().pretty();


////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 0 Очистити все
db.orders.deleteMany({});

// 1 Створіть кілька замовлень з різними наборами товарів, але так щоб один з товарів був у декількох замовленнях
db.orders.insertMany([
  {
    order_number: 1001,
    date: ISODate("2023-01-15"),
    total_sum: 500,
    customer: {
      name: "Andrii",
      surname: "Zhuravchak",
      phones: [9876543, 1234567],
      address: "Lviv, UA"
    },
    payment: {
      card_owner: "Andrii Zhuravchak",
      cardId: 12345678
    },
    // Посилання на товари через ObjectId
    items_id: [
      ObjectId("679e0b67e81285eac2c191b7"),
      ObjectId("679e0b67e81285eac2c191b8")
    ]
  },
  {
    order_number: 1002,
    date: ISODate("2023-02-20"),
    total_sum: 750,
    customer: {
      name: "Oksana",
      surname: "Kh",
      phones: [1111111],
      address: "Kyiv, UA"
    },
    payment: {
      card_owner: "Oksana Kh",
      cardId: 87654321
    },
    items_id: [
      // Той самий товар, що й в попередньому замовленні
      ObjectId("679e0b67e81285eac2c191b7"),
      ObjectId("679e0b67e81285eac2c191b9")
    ]
  },
  {
    order_number: 1003,
    date: ISODate("2023-03-05"),
    total_sum: 300,
    customer: {
      name: "Andrii",
      surname: "Zhuravchak",
      phones: [9876543, 1234567],
      address: "Lviv, UA"
    },
    payment: {
      card_owner: "Andrii Zhuravchak",
      cardId: 12345678
    },
    items_id: [
      ObjectId("679e0b67e81285eac2c191ba")
    ]
  }
]);

// 2 Виведіть всі замовлення
db.items.find().pretty();

// 3 Виведіть замовлення з вартістю більше певного значення
db.orders.find({ total_sum: { $gt: 400 } }).pretty();

// 4 Знайдіть замовлення зроблені одним замовником
db.orders.find({
  "customer.name": "Andrii",
  "customer.surname": "Zhuravchak"
}).pretty();

// 5 Знайдіть всі замовлення з певним товаром (товарами) (шукати можна по ObjectId)
db.orders.find({ items_id: ObjectId("679e0b67e81285eac2c191b7") }).pretty();

// 6 Додайте в усі замовлення з певним товаром ще один товар і збільште 
// існуючу вартість замовлення на деяке значення Х
db.orders.updateMany(
  { items_id: ObjectId("679e0b67e81285eac2c191b7") },
  {
    // Використання $addToSet дозволяє уникнути дублювання, якщо потрібно
    $addToSet: { items_id: ObjectId("679e0b67e81285eac2c191bb") },
    $inc: { total_sum: 100 }
  }
);

db.orders.find().pretty();

// 7 Виведіть кількість товарів в певному замовленні
db.orders.aggregate([
  { $match: { order_number: 1001 } },
  {
    $project: {
      _id: 0,
      order_number: 1,
      items_count: { $size: "$items_id" }
    }
  }
]);

// 8 Виведіть тільки інформацію про кастомера і номери кредитної карт, для
// замовлень вартість яких перевищує певну суму
db.orders.find(
  { total_sum: { $gt: 400 } },
  { _id: 0, customer: 1, "payment.cardId": 1 }
).pretty();

// 9 Видаліть товар з замовлень, зроблених за певний період дат
db.orders.updateMany(
  { date: { $gte: ISODate("2023-02-01"), $lte: ISODate("2023-02-28") } },
  { $pull: { items_id: ObjectId("679e0b67e81285eac2c191b9") } }
);
db.orders.find().pretty();

// 10 Перейменуйте у всіх замовлення ім'я (прізвище) замовника
db.orders.updateMany(
  { "customer.name": "Andrii" },
  { $set: { "customer.name": "John" } }
);
db.orders.find().pretty();


// 11 Знайдіть замовлення зроблені одним замовником, і виведіть тільки
// інформацію про кастомера та товари у замовлені підставивши замість
// ObjectId("***") назви товарів та їх вартість (аналог join-а між таблицями
// orders та items).


db.orders.aggregate([
  { $match: { "customer.name": "John" } },
  // Об'єднуємо дані з колекції items по полю items_id
  {
    $lookup: {
      from: "items",
      localField: "items_id",
      foreignField: "_id",
      as: "items_details"
    }
  },
  // Проекція: виводимо інформацію про замовника та перетворюємо масив items_details
  {
    $project: {
      _id: 0,
      customer: 1,
      // За допомогою $map вибираємо тільки необхідні поля для кожного товару
      items: {
        $map: {
          input: "$items_details",
          as: "item",
          in: {
              name: "$$item.category",  // або "$$item.name", залежно від структури товару
              price: "$$item.price"
          }
        }
      }
    }
  }
]);



////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////


// Створіть Сapped collection яка б містила 5 останніх відгуків на наш
// інтернет-магазин. Структуру запису визначіть самостійно.
// 1) Перевірте що при досягненні обмеження старі відгуки будуть затиратись

db.createCollection("reviews", {
  capped: true,
  size: 5000, // розмір у байтах; підберіть значення, яке підходить для ваших документів
  max: 5      // максимальна кількість документів — 5 відгуків
});

db.reviews.insertMany([
  { customerName: "Ivan", rating: 4, review: "Good shop! Fast delivery.", date: new Date() },
  { customerName: "Oksana", rating: 5, review: "Excellent service.", date: new Date() },
  { customerName: "Petro", rating: 3, review: "Average experience.", date: new Date() },
  { customerName: "Anna", rating: 4, review: "Nice website and friendly staff.", date: new Date() },
  { customerName: "Dmytro", rating: 2, review: "Not satisfied with the support.", date: new Date() }
]);

db.reviews.find().sort({ $natural: 1 }).pretty();

db.reviews.insertOne({ customerName: "Svitlana", rating: 5, review: "Amazing! Will buy again.", date: new Date() });

db.reviews.find().sort({ $natural: 1 }).pretty();


