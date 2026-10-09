drop database if exists olist_kpi_framework;
create database olist_kpi_framework
    character set utf8mb4
    collate utf8mb4_unicode_ci;

use olist_kpi_framework;

-- schema

create table olist_customers (
    customer_id char(32) primary key,
    customer_unique_id char(32) not null,
    customer_zip_code_prefix int not null,
    customer_city varchar(120) not null,
    customer_state char(2) not null,
    index idx_customers_unique (customer_unique_id),
    index idx_customers_zip (customer_zip_code_prefix)
);

create table olist_products (
    product_id char(32) primary key,
    product_category_name varchar(120),
    product_name_lenght int,
    product_description_lenght int,
    product_photos_qty int,
    product_weight_g decimal(10,2),
    product_length_cm decimal(10,2),
    product_height_cm decimal(10,2),
    product_width_cm decimal(10,2),
    index idx_products_category (product_category_name)
);

create table olist_sellers (
    seller_id char(32) primary key,
    seller_zip_code_prefix int not null,
    seller_city varchar(120) not null,
    seller_state char(2) not null,
    index idx_sellers_zip (seller_zip_code_prefix)
);

create table product_category_name_translation (
    product_category_name varchar(120) primary key,
    product_category_name_english varchar(120) not null
);

create table olist_orders (
    order_id char(32) primary key,
    customer_id char(32) not null,
    order_status varchar(30) not null,
    order_purchase_timestamp datetime not null,
    order_approved_at datetime,
    order_delivered_carrier_date datetime,
    order_delivered_customer_date datetime,
    order_estimated_delivery_date datetime,
    constraint fk_orders_customer
        foreign key (customer_id) references olist_customers(customer_id),
    index idx_orders_customer (customer_id),
    index idx_orders_status (order_status),
    index idx_orders_purchase (order_purchase_timestamp)
);

create table olist_order_items (
    order_id char(32) not null,
    order_item_id int not null,
    product_id char(32) not null,
    seller_id char(32) not null,
    shipping_limit_date datetime not null,
    price decimal(12,2) not null,
    freight_value decimal(12,2) not null,
    primary key (order_id, order_item_id),
    constraint fk_items_order
        foreign key (order_id) references olist_orders(order_id),
    constraint fk_items_product
        foreign key (product_id) references olist_products(product_id),
    constraint fk_items_seller
        foreign key (seller_id) references olist_sellers(seller_id),
    index idx_items_product (product_id),
    index idx_items_seller (seller_id)
);

create table olist_order_reviews (
    review_id char(32) not null,
    order_id char(32) not null,
    review_score tinyint not null,
    review_comment_title text,
    review_comment_message text,
    review_creation_date datetime not null,
    review_answer_timestamp datetime not null,
    primary key (review_id, order_id),
    constraint fk_reviews_order
        foreign key (order_id) references olist_orders(order_id),
    index idx_reviews_order (order_id)
);

create table olist_order_payments (
    order_id char(32) not null,
    payment_sequential int not null,
    payment_type varchar(30) not null,
    payment_installments int not null,
    payment_value decimal(12,2) not null,
    primary key (order_id, payment_sequential),
    constraint fk_payments_order
        foreign key (order_id) references olist_orders(order_id),
    index idx_payments_order (order_id)
);

create table olist_geolocation (
    geolocation_id bigint auto_increment primary key,
    geolocation_zip_code_prefix int not null,
    geolocation_lat decimal(11,8) not null,
    geolocation_lng decimal(11,8) not null,
    geolocation_city varchar(120) not null,
    geolocation_state char(2) not null,
    index idx_geo_zip (geolocation_zip_code_prefix)
);


-- q1: row counts and order -> item cardinality

with item_cardinality as (
    select
        order_id,
        count(*) as item_count
    from olist_order_items
    group by order_id
)
select 'olist_customers' as metric, cast(count(*) as decimal(20,4)) as value
from olist_customers
union all
select 'olist_geolocation', count(*) from olist_geolocation
union all
select 'olist_order_items', count(*) from olist_order_items
union all
select 'olist_order_payments', count(*) from olist_order_payments
union all
select 'olist_order_reviews', count(*) from olist_order_reviews
union all
select 'olist_orders', count(*) from olist_orders
union all
select 'olist_products', count(*) from olist_products
union all
select 'olist_sellers', count(*) from olist_sellers
union all
select 'product_category_name_translation', count(*) from product_category_name_translation
union all
select 'orders_with_items', count(*) from item_cardinality
union all
select 'avg_items_per_order', round(avg(item_count), 4) from item_cardinality
union all
select 'max_items_in_order', max(item_count) from item_cardinality
union all
select
    'orders_without_items',
    (
        select count(*)
        from olist_orders o
        left join olist_order_items oi
            on o.order_id = oi.order_id
        where oi.order_id is null
    )
from dual
;

-- output: 99,441 orders; 112,650 order-item rows; 98,666 orders with items
-- output: avg items/order = 1.1417, max items/order = 21, orders without items = 775


-- q2: reusable delivered item-grain analytical view

create or replace view vw_delivered_item_base as
select
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    date_format(o.order_purchase_timestamp, '%Y-%m') as purchase_month,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    datediff(o.order_delivered_customer_date, o.order_purchase_timestamp) as delivery_days,
    case
        when o.order_delivered_customer_date is null
          or o.order_estimated_delivery_date is null then null
        when o.order_delivered_customer_date <= o.order_estimated_delivery_date then 1
        else 0
    end as on_time_flag,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    p.product_category_name,
    coalesce(t.product_category_name_english, 'unknown') as category_name_english,
    r.review_score,
    r.review_count,
    s.seller_city,
    s.seller_state
from olist_orders o
inner join olist_order_items oi
    on o.order_id = oi.order_id
left join olist_products p
    on oi.product_id = p.product_id
left join product_category_name_translation t
    on p.product_category_name = t.product_category_name
left join (
    select
        order_id,
        avg(review_score) as review_score,
        count(*) as review_count
    from olist_order_reviews
    group by order_id
) r
    on o.order_id = r.order_id
left join olist_sellers s
    on oi.seller_id = s.seller_id
where o.order_status = 'delivered'
;

-- output: item-grain view = 110,197 rows across 96,478 delivered orders

-- q2 join audit

with
delivered_orders as (
    select order_id
    from olist_orders
    where order_status = 'delivered'
),
item_stage as (
    select
        o.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id
    from delivered_orders o
    inner join olist_order_items oi
        on o.order_id = oi.order_id
),
product_stage as (
    select
        i.*,
        p.product_category_name,
        case when p.product_id is null then 1 else 0 end as product_unmatched
    from item_stage i
    left join olist_products p
        on i.product_id = p.product_id
),
translation_stage as (
    select
        p.*,
        t.product_category_name_english,
        case when t.product_category_name is null then 1 else 0 end as translation_unmatched
    from product_stage p
    left join product_category_name_translation t
        on p.product_category_name = t.product_category_name
),
review_order as (
    select
        order_id,
        avg(review_score) as review_score
    from olist_order_reviews
    group by order_id
),
review_stage as (
    select
        t.*,
        r.review_score,
        case when r.order_id is null then 1 else 0 end as review_unmatched
    from translation_stage t
    left join review_order r
        on t.order_id = r.order_id
),
seller_stage as (
    select
        r.*,
        case when s.seller_id is null then 1 else 0 end as seller_unmatched
    from review_stage r
    left join olist_sellers s
        on r.seller_id = s.seller_id
)
select
    '01 delivered orders' as stage,
    count(*) as row_count,
    count(distinct order_id) as distinct_orders,
    0 as unmatched
from delivered_orders
union all
select
    '02 inner join order_items',
    count(*),
    count(distinct order_id),
    0
from item_stage
union all
select
    '03 left join products',
    count(*),
    count(distinct order_id),
    sum(product_unmatched)
from product_stage
union all
select
    '04 left join translation',
    count(*),
    count(distinct order_id),
    sum(translation_unmatched)
from translation_stage
union all
select
    '05 left join review aggregate',
    count(*),
    count(distinct order_id),
    count(distinct case when review_unmatched = 1 then order_id end)
from review_stage
union all
select
    '06 left join sellers',
    count(*),
    count(distinct order_id),
    sum(seller_unmatched)
from seller_stage
;

-- output: only orders -> items expands the row count: 96,478 -> 110,197; products unmatched = 0; translation unmatched item rows = 1,559
-- output: delivered orders without review = 646; seller unmatched = 0


-- q3: mandatory revenue reconciliation

with
direct_revenue as (
    select
        sum(oi.price) as revenue
    from olist_orders o
    inner join olist_order_items oi
        on o.order_id = oi.order_id
    where o.order_status = 'delivered'
),
naive_review_join as (
    select
        sum(oi.price) as revenue
    from olist_orders o
    inner join olist_order_items oi
        on o.order_id = oi.order_id
    left join olist_order_reviews r
        on o.order_id = r.order_id
    where o.order_status = 'delivered'
),
fixed_view as (
    select
        sum(price) as revenue
    from vw_delivered_item_base
)
select
    'direct delivered items' as method,
    round(d.revenue, 2) as revenue_brl,
    0.00 as difference_vs_direct,
    0.0000 as difference_pct
from direct_revenue d

union all

select
    'naive raw-review join',
    round(n.revenue, 2),
    round(n.revenue - d.revenue, 2),
    round(100 * (n.revenue - d.revenue) / d.revenue, 4)
from naive_review_join n
cross join direct_revenue d

union all

select
    'fixed analytical view',
    round(f.revenue, 2),
    round(f.revenue - d.revenue, 2),
    round(100 * (f.revenue - d.revenue) / d.revenue, 4)
from fixed_view f
cross join direct_revenue d
;

-- output: direct = 13,221,498.11 BRL
-- output: naive raw-review join = 13,279,836.59 BRL (+58,338.48; +0.4412%)
-- output: fixed view = 13,221,498.11 BRL; difference = 0.00


-- q4: overall core kpis, delivered orders only

with order_level as (
    select
        order_id,
        sum(price) as order_revenue,
        max(delivery_days) as delivery_days,
        max(review_score) as review_score
    from vw_delivered_item_base
    group by order_id
)
select
    count(*) as delivered_orders,
    round(sum(order_revenue), 2) as total_revenue_brl,
    round(avg(order_revenue), 2) as aov_brl,
    round(avg(delivery_days), 2) as avg_delivery_days,
    round(avg(review_score), 2) as avg_review_score
from order_level
;

-- output: 96,478 delivered orders
-- output: revenue = 13,221,498.11 BRL; aov = 137.04 BRL
-- output: avg delivery = 12.50 days; avg review = 4.16 / 5


-- q5: category kpis

with order_category as (
    select
        category_name_english,
        order_id,
        sum(price) as category_order_revenue,
        max(delivery_days) as delivery_days,
        max(review_score) as review_score
    from vw_delivered_item_base
    group by category_name_english, order_id
)
select
    category_name_english,
    round(sum(category_order_revenue), 2) as total_revenue_brl,
    count(*) as order_count,
    round(avg(category_order_revenue), 2) as aov_brl,
    round(avg(delivery_days), 2) as avg_delivery_days,
    round(avg(review_score), 2) as avg_review_score
from order_category
group by category_name_english
order by total_revenue_brl desc
;

-- output: 72 category groups including 'unknown'
-- output: top revenue categories: health_beauty 1,233,131.72;
-- output: watches_gifts 1,166,176.98; bed_bath_table 1,023,434.76 BRL


-- q6: monthly kpis

with order_month as (
    select
        purchase_month,
        order_id,
        sum(price) as order_revenue,
        max(delivery_days) as delivery_days,
        max(review_score) as review_score
    from vw_delivered_item_base
    group by purchase_month, order_id
)
select
    purchase_month,
    round(sum(order_revenue), 2) as total_revenue_brl,
    count(*) as order_count,
    round(avg(order_revenue), 2) as aov_brl,
    round(avg(delivery_days), 2) as avg_delivery_days,
    round(avg(review_score), 2) as avg_review_score
from order_month
group by purchase_month
order by purchase_month
;

-- output: 23 observed purchase months from 2016-09 to 2018-08 || peak delivered revenue = 987,765.37 BRL in 2017-11


-- q7: top and bottom 5 categories by revenue

with category_revenue as (
    select
        category_name_english,
        sum(price) as total_revenue_brl,
        count(distinct order_id) as order_count
    from vw_delivered_item_base
    group by category_name_english
),
ranked as (
    select
        *,
        row_number() over(order by total_revenue_brl desc) as top_rank,
        row_number() over(order by total_revenue_brl asc) as bottom_rank
    from category_revenue
)
select
    case when top_rank <= 5 then 'top 5' else 'bottom 5' end as segment,
    category_name_english,
    round(total_revenue_brl, 2) as total_revenue_brl,
    order_count
from ranked
where top_rank <= 5 or bottom_rank <= 5
order by segment desc, total_revenue_brl desc
;

-- output top 5: health_beauty; watches_gifts; bed_bath_table; sports_leisure; computers_accessories
-- output bottom 5: security_and_services; fashion_childrens_clothes; cds_dvds_musicals; home_comfort_2; flowers


-- q8: top and bottom 5 categories by review score / minimum volume is enforced with having

with order_category as (
    select
        category_name_english,
        order_id,
        max(review_score) as review_score,
        sum(price) as category_order_revenue
    from vw_delivered_item_base
    group by category_name_english, order_id
),
eligible_categories as (
    select
        category_name_english,
        count(*) as order_count,
        avg(review_score) as avg_review_score,
        sum(category_order_revenue) as total_revenue_brl
    from order_category
    group by category_name_english
    having count(*) >= 100
),
ranked as (
    select
        *,
        row_number() over(order by avg_review_score desc) as top_rank,
        row_number() over(order by avg_review_score asc) as bottom_rank
    from eligible_categories
)
select
    case when top_rank <= 5 then 'top 5' else 'bottom 5' end as segment,
    category_name_english,
    order_count,
    round(avg_review_score, 3) as avg_review_score,
    round(total_revenue_brl, 2) as total_revenue_brl
from ranked
where top_rank <= 5 or bottom_rank <= 5
order by segment desc, avg_review_score desc
;

-- output: best eligible category -> books_general_interest = 4.535 across 496 orders || worst eligible category: office_furniture = 3.643 across 1,254 orders


-- q9: seller kpis and revenue rank

with order_seller as (
    select
        seller_id,
        order_id,
        sum(price) as seller_order_revenue,
        max(review_score) as review_score,
        max(delivery_days) as delivery_days
    from vw_delivered_item_base
    group by seller_id, order_id
),
seller_metrics as (
    select
        seller_id,
        sum(seller_order_revenue) as total_revenue_brl,
        count(*) as order_count,
        avg(review_score) as avg_review_score,
        avg(delivery_days) as avg_delivery_days
    from order_seller
    group by seller_id
)
select
    seller_id,
    round(total_revenue_brl, 2) as total_revenue_brl,
    order_count,
    round(avg_review_score, 3) as avg_review_score,
    round(avg_delivery_days, 2) as avg_delivery_days,
    rank() over(order by total_revenue_brl desc) as revenue_rank
from seller_metrics
order by revenue_rank, seller_id
;

-- output: 2,970 delivered-order sellers || rank 1 seller 4869f7a5dfa277a7dca6462dcf3b52b2 = 226,987.93 BRL


-- q10: category delivery vs satisfaction

with order_category as (
    select
        category_name_english,
        order_id,
        sum(price) as category_order_revenue,
        max(delivery_days) as delivery_days,
        max(review_score) as review_score
    from vw_delivered_item_base
    group by category_name_english, order_id
)
select
    category_name_english,
    count(*) as order_count,
    round(sum(category_order_revenue), 2) as total_revenue_brl,
    round(avg(delivery_days), 3) as avg_delivery_days,
    round(avg(review_score), 3) as avg_review_score
from order_category
group by category_name_english
order by total_revenue_brl desc
;

-- output: notebook correlation across category averages = -0.4990; slower category-level delivery generally tracks lower review scores



-- bonus q11: on-time delivery rate

with order_level as (
    select
        order_id,
        max(on_time_flag) as on_time_flag
    from vw_delivered_item_base
    group by order_id
)
select
    count(*) as delivered_orders,
    round(100.0 * avg(on_time_flag), 2) as on_time_rate_pct
from order_level;

-- output: overall on-time delivery rate = 93.23%


-- bonus q12: anti-join orders with no review

with delivered_orders as (
    select order_id
    from olist_orders
    where order_status = 'delivered'
),
orders_without_review as (
    select
        o.order_id
    from delivered_orders o
    left join olist_order_reviews r
        on o.order_id = r.order_id
    where r.order_id is null
)
select
    (select count(*) from delivered_orders) as delivered_orders,
    count(*) as orders_without_review,
    round(
        100 * count(*) / (select count(*) from delivered_orders),
        3
    ) as no_review_share_pct
from orders_without_review
;

-- output: 646 of 96,478 delivered orders have no review = 0.670%


-- bonus q13: freight-to-revenue pressure by category

-- freight_value is treated as a shipping-burden proxy, not accounting profit.

select
    category_name_english,
    count(distinct order_id) as order_count,
    round(sum(price), 2) as product_revenue_brl,
    round(sum(freight_value), 2) as freight_brl,
    round(100 * sum(freight_value) / nullif(sum(price), 0), 2) as freight_to_revenue_pct,
    case
        when sum(freight_value) / nullif(sum(price), 0) >= 0.30 then 'high freight pressure'
        when sum(freight_value) / nullif(sum(price), 0) >= 0.20 then 'watch'
        else 'normal'
    end as freight_flag
from vw_delivered_item_base
group by category_name_english
order by freight_to_revenue_pct desc
;

-- output: overall delivered freight/product-revenue ratio = 16.63% || among 100+ order categories, christmas_supplies = 36.52%;
-- output: signaling_and_security = 30.39%; electronics = 29.46%


-- bonus q14: category share of monthly revenue

with monthly_category as (
    select
        purchase_month,
        category_name_english,
        sum(price) as category_revenue_brl
    from vw_delivered_item_base
    group by purchase_month, category_name_english
)
select
    purchase_month,
    category_name_english,
    round(category_revenue_brl, 2) as category_revenue_brl,
    round(
        100 * category_revenue_brl
        / sum(category_revenue_brl) over(partition by purchase_month),
        2
    ) as monthly_revenue_share_pct,
    rank() over(
        partition by purchase_month
        order by category_revenue_brl desc
    ) as monthly_category_rank
from monthly_category
order by purchase_month, monthly_category_rank, category_name_english
;

-- output example: 2018-08 health_beauty = 14.24% of delivered monthly revenue || 2018-02 computers_accessories = 12.12%


-- addition q15: seller concentration

with seller_revenue as (
    select
        seller_id,
        sum(price) as total_revenue_brl
    from vw_delivered_item_base
    group by seller_id
),
ranked as (
    select
        *,
        row_number() over(order by total_revenue_brl desc) as revenue_rank
    from seller_revenue
)
select
    round(sum(case when revenue_rank <= 10 then total_revenue_brl else 0 end), 2) as top_10_revenue_brl,
    round(sum(total_revenue_brl), 2) as total_revenue_brl,
    round(
        100 * sum(case when revenue_rank <= 10 then total_revenue_brl else 0 end)
        / sum(total_revenue_brl),
        2
    ) as top_10_revenue_share_pct
from ranked
;

-- output: top 10 sellers generate 13.27% of delivered product revenue
