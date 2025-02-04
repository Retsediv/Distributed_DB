// 0. Populate data

// CREATE items
CREATE (item1:Item {id: 1, name: "Laptop", price: 1000}),
       (item2:Item {id: 2, name: "Smartphone", price: 500}),
       (item3:Item {id: 3, name: "Headphones", price: 200});

// CREATE customers
CREATE (customer1:Customer {id: 1, name: "Alice"}),
       (customer2:Customer {id: 2, name: "Bob"});

// CREATE orders
CREATE (order1:Order {id: 1, date: "2024-01-15"}),
       (order2:Order {id: 2, date: "2024-01-20"}),
       (order3:Order {id: 3, date: "2024-02-05"});


// BOUGHT
MATCH (c:Customer {id: 1}), (o:Order {id: 1})
CREATE (c)-[:BOUGHT]->(o);

MATCH (c:Customer {id: 1}), (o:Order {id: 2})
CREATE (c)-[:BOUGHT]->(o);

MATCH (c:Customer {id: 2}), (o:Order {id: 3})
CREATE (c)-[:BOUGHT]->(o);



// CONTAINS
// order 1 has item1 and item3
MATCH (o:Order {id: 1}), (i:Item {id: 1})
CREATE (o)-[:CONTAINS]->(i);

MATCH (o:Order {id: 1}), (i:Item {id: 3})
CREATE (o)-[:CONTAINS]->(i);

// order 2 has item2
MATCH (o:Order {id: 2}), (i:Item {id: 2})
CREATE (o)-[:CONTAINS]->(i);

// order 3 has item1 and item2
MATCH (o:Order {id: 3}), (i:Item {id: 1})
CREATE (o)-[:CONTAINS]->(i);

MATCH (o:Order {id: 3}), (i:Item {id: 2})
CREATE (o)-[:CONTAINS]->(i);


// VIEW
// Alice переглянула Smartphone (item2)
MATCH (c:Customer {id: 1}), (i:Item {id: 2})
CREATE (c)-[:VIEW]->(i);

MATCH (c:Customer {id: 2}), (i:Item {id: 3})
CREATE (c)-[:VIEW]->(i);



// 1. Знайти Items які входять в конкретний Order (за Order id)

MATCH (o:Order {id: 2})-[:CONTAINS]->(i:Item)
RETURN i;

// 2. Підрахувати вартість конкретного Order

MATCH (o:Order {id: 3})-[:CONTAINS]->(i:Item)
RETURN sum(i.price) AS orderTotal;

// 3. Знайти всі Orders конкретного Customer

MATCH (c:Customer {id: 1})-[:BOUGHT]->(o:Order)
RETURN o;

// 4. Знайти всі Items куплені конкретним Customer (через його Orders)

MATCH (c:Customer {id: 1})-[:BOUGHT]->(o:Order)-[:CONTAINS]->(i:Item)
RETURN DISTINCT i;

// 5. Знайти загальну кількість Items куплені конкретним Customer (через його Order)

MATCH (c:Customer {id: 1})-[:BOUGHT]->(o:Order)-[:CONTAINS]->(i:Item)
RETURN count(i) AS totalItems;

// 6. Знайти для Customer на яку загальну суму він придбав товарів (через його Order)

MATCH (c:Customer {id: 1})-[:BOUGHT]->(o:Order)-[:CONTAINS]->(i:Item)
RETURN sum(i.price) AS totalSpent;

// 7. Знайті скільки разів кожен товар був придбаний, відсортувати за цим значенням

MATCH (i:Item)<-[:CONTAINS]-(:Order)
RETURN i.id, i.name, count(*) AS purchaseCount
ORDER BY purchaseCount DESC;

// 8. Знайти всі Items переглянуті (view) конкретним Customer

MATCH (c:Customer {id: 2})-[:VIEW]->(i:Item)
RETURN i;

// 9. Знайти інші Items що купувались разом з конкретним Item (тобто всі Items що входять до Order-s разом з даними Item)

MATCH (target:Item {id: 1})<-[:CONTAINS]-(o:Order)-[:CONTAINS]->(other:Item)
WHERE other.id <> target.id
RETURN DISTINCT other;

// 10. Знайти Customers які купили даний конкретний Item

MATCH (i:Item {id: 1})<-[:CONTAINS]-(o:Order)<-[:BOUGHT]-(c:Customer)
RETURN DISTINCT c;

// 11. Знайти для певного Customer(а) товари, які він переглядав, але не купив

MATCH (c:Customer {id: 2})-[:VIEW]->(i:Item)
WHERE NOT (c)-[:BOUGHT]->(:Order)-[:CONTAINS]->(i)
RETURN DISTINCT i;

