# Olist E-Commerce Data Analysis (SQL)

[![Tableau](https://img.shields.io/badge/Tableau-Interactive_Dashboard-E97627?style=for-the-badge&logo=tableau&logoColor=white)](https://public.tableau.com/views/OlistE-CommerceAnalysis_17941327576920/Dashboard1?:language=en-GB&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
[![MySQL](https://img.shields.io/badge/MySQL-00618A?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Kaggle Dataset](https://img.shields.io/badge/Kaggle-Olist_Dataset-20BEFF?style=for-the-badge&logo=kaggle&logoColor=white)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)


---

### 🔗 Interactive BI Dashboard
> **Explore the interactive dashboard on Tableau Public:**  
> 🌐 **[View Live Tableau Dashboard](https://public.tableau.com/views/OlistE-CommerceAnalysis_17941327576920/Dashboard1?:language=en-GB&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**

---

## Highlights

- **99,441 orders** placed between **Sept 2016 and Oct 2018**, from **96,096 unique customers** and **3,095 sellers**.
- **R$13.22M** in revenue from delivered orders, with an average order value of **R$137.04**.
- Revenue and order volume both peaked in **November 2017** (7,289 orders, R$987,765).
- **Health & Beauty**, **Watches & Gifts** and **Bed, Bath & Table** are the top three categories by revenue.
- Average delivery takes **12.5 days**, and **6.77%** of delivered orders arrive after the estimated date.
- Late deliveries hurt satisfaction: average review score **4.29 on time vs 2.27 late**.
- **Credit card** is the dominant payment method, and most customers pay in **1 installment**.
- **São Paulo (SP)** dominates the platform in orders, revenue, sellers and customers, and has the fastest delivery times.

## Business questions answered

| Area | Question |
|------|----------|
| Data checks | How many sellers, products, customers, orders, items, payments and reviews exist? Are all `order_items` rows linked to an order? |
| Sales | Earliest and latest order, orders per status, monthly orders and revenue, average order value |
| Behaviour | Which day of the week and hour of the day do customers buy most? |
| Products | Top 10 categories by revenue vs by orders, each category's share of revenue, highest and lowest priced categories |
| Geography | Which states and cities generate the most orders and revenue? Sellers vs customers by state |
| Freight | Freight cost by state and as a percentage of item price |
| Delivery | Average delivery time overall and by state, actual vs estimated delivery, late rate by state |
| Reviews | Score distribution, late vs on-time review scores, lowest-rated categories |
| Payments | Payment methods used and typical number of installments |

## Dataset

The data is the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) on Kaggle. It is **not included in this repository**. Download it and place the CSV files in a local `archive/` folder (this folder is git-ignored).

| Table | CSV file | Rows |
|-------|----------|------|
| `customers` | `olist_customers_dataset.csv` | 99,441 |
| `orders` | `olist_orders_dataset.csv` | 99,441 |
| `order_items` | `olist_order_items_dataset.csv` | 112,650 |
| `order_payments` | `olist_order_payments_dataset.csv` | 103,886 |
| `order_reviews` | `olist_order_reviews_dataset.csv` | 99,224 |
| `products` | `olist_products_dataset.csv` | 32,951 |
| `sellers` | `olist_sellers_dataset.csv` | 3,095 |
| `product_category` | `product_category_name_translation.csv` | 71 |
| `geolocation` | `olist_geolocation_dataset.csv` | 1,000,163 |

### How the tables relate

```
customers ──< orders ──< order_items >── products >── product_category
                 │            │
                 │            └──────── sellers
                 ├──< order_payments
                 └──< order_reviews
geolocation joins to customers / sellers on zip code prefix
```

## Repository structure

```
olist-data-analysis/
├── olist-db.sql       # Creates the database and all tables
├── olist-query.sql    # Data checks and business-question queries
├── README.md
├── LICENSE
└── .gitignore
```

The Tableau dashboard is hosted on Tableau Public (see the link above).

## Getting started

**Requirements:** MySQL 8.0 or later (MySQL Workbench or the `mysql` command line).

**1. Create the database and tables**

```sql
SOURCE olist-db.sql;
```

**2. Load the CSV files**

Enable local file loading, then connect with the flag turned on:

```bash
mysql --local-infile=1 -u root -p olist_database
```
```sql
SET GLOBAL local_infile = 1;
```

Run the loads below, replacing `<path>` with the folder that holds the CSVs. Empty date and number fields are converted to `NULL`, otherwise MySQL drops those rows.

```sql
LOAD DATA LOCAL INFILE '<path>/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '<path>/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(order_id, customer_id, order_status, @a, @b, @c, @d, @e)
SET order_purchase_timestamp      = NULLIF(@a, ''),
    order_approved_at             = NULLIF(@b, ''),
    order_delivered_carrier_date  = NULLIF(@c, ''),
    order_delivered_customer_date = NULLIF(@d, ''),
    order_estimated_delivery_date = NULLIF(@e, '');

LOAD DATA LOCAL INFILE '<path>/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '<path>/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '<path>/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '<path>/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(product_id, product_category_name, @a, @b, @c, @d, @e, @f, @g)
SET product_name_lenght        = NULLIF(@a, ''),
    product_description_lenght = NULLIF(@b, ''),
    product_photos_qty         = NULLIF(@c, ''),
    product_weight_g           = NULLIF(@d, ''),
    product_length_cm          = NULLIF(@e, ''),
    product_height_cm          = NULLIF(@f, ''),
    product_width_cm           = NULLIF(@g, '');

LOAD DATA LOCAL INFILE '<path>/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '<path>/product_category_name_translation.csv'
INTO TABLE product_category
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '<path>/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
```

**3. Check the row counts** against the table above, then run the queries in `olist-query.sql`.

## Notes and limitations

- Revenue is calculated from item `price` and excludes freight. Monthly revenue, average order value and the state and city revenue figures use **delivered** orders only. The category analysis covers all order statuses.
- Two product categories (`pc_gamer` and `portateis_cozinha_e_preparadores_de_alimentos`) and products with no category are missing from the translation table, so about 1,600 order items are left out of category-level results.
- `review_id` is not unique in the source data (the same review appears on more than one order), so `order_reviews` has no primary key.
- The column names `product_name_lenght` and `product_description_lenght` keep the misspelling from the source data.

## Skills demonstrated

Database design, bulk data loading, data validation, joins, aggregation, CTEs, `CASE` logic, date functions, and translating query results into business insights with Tableau dashboards.

## License

The code in this repository is released under the [MIT License](LICENSE). The Olist dataset is a separate work, licensed by its publisher under CC BY-NC-SA 4.0, and is not redistributed here.

## Author

**Etini Unaam**
# olist-ecommerce-analytics
