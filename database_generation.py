"""
=====================================================================
EGYPTIAN PHARMACY CHAIN — SYNTHETIC DATA GENERATOR
=====================================================================

Purpose: Generate realistic pharmacy business data for SQL + Power BI project
Output: 7 CSV files ready for SQL database import

Dataset Size:
- 10 Branches across Egypt
- 200 Medications
- 50 Employees
- 50,000 Sales transactions (2 years)
- 500+ Inventory records
- 10 Suppliers
- 1,000 Purchase orders

Author: Ahmed El-Shahat
=====================================================================
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

np.random.seed(42)
random.seed(42)

print("EGYPTIAN PHARMACY CHAIN — DATA GENERATION")

# =====================================================================
# CONFIGURATION
# =====================================================================

N_BRANCHES = 10
N_MEDICATIONS = 200
N_EMPLOYEES = 50
N_SALES = 50_000
N_SUPPLIERS = 10
N_PURCHASE_ORDERS = 1_000

DATE_START = datetime(2023, 1, 1)
DATE_END = datetime(2024, 12, 31)

# =====================================================================
# TABLE 1: BRANCHES
# =====================================================================

print("\n[1/7] Generating BRANCHES")

governorates = ['Cairo', 'Giza', 'Alexandria', 'Dakahlia', 'Sharqia',
                'Qalyubia', 'Beheira', 'Gharbia']
cities = {
    'Cairo': ['Nasr City', 'Heliopolis', 'Maadi', 'Downtown'],
    'Giza': ['Dokki', 'Mohandeseen', '6th October', 'Haram'],
    'Alexandria': ['Smouha', 'Sidi Gaber', 'Sporting', 'Downtown'],
    'Dakahlia': ['Mansoura', 'Mit Ghamr', 'Talkha'],
    'Sharqia': ['Zagazig', '10th of Ramadan', 'Belbeis'],
    'Qalyubia': ['Benha', 'Shubra El-Kheima', 'Qalyub'],
    'Beheira': ['Damanhur', 'Kafr El Dawwar'],
    'Gharbia': ['Tanta', 'Mahalla', 'Zifta']}

branches_data = []
for i in range(1, N_BRANCHES + 1):
    gov = random.choice(governorates)
    city = random.choice(cities[gov])

    branches_data.append({
        'branch_id': i,
        'branch_name': f'CNS Pharmacy - {city}',
        'governorate': gov,
        'city': city,
        'manager_name': f'Manager_{i:02d}',
        'opening_date': (DATE_START - timedelta(days=random.randint(365, 3650))).date(),
        'square_meters': random.randint(60, 250)
    })

branches_df = pd.DataFrame(branches_data)
print(f"✓ Created {len(branches_df)} branches")

# =====================================================================
# TABLE 2: MEDICATIONS
# =====================================================================

print("\n[2/7] Generating MEDICATIONS")

categories = [
    'Antibiotics', 'Cardiovascular', 'Diabetes', 'Pain Relief',
    'Respiratory', 'Gastrointestinal', 'Vitamins', 'Dermatology',
    'Neurological', 'Pediatric']

manufacturers = [
    'Pharco', 'EVA Pharma', 'Sanofi', 'Pfizer', 'Novartis',
    'GSK', 'Amoun', 'EIPICO', 'Hikma', 'AstraZeneca']

med_names = {
    'Antibiotics': ['Amoxicillin', 'Azithromycin', 'Ciprofloxacin', 'Cephalexin',
                    'Augmentin', 'Flagyl', 'Clindamycin'],
    'Cardiovascular': ['Atenolol', 'Amlodipine', 'Enalapril', 'Losartan',
                       'Aspirin Cardio', 'Clopidogrel', 'Simvastatin'],
    'Diabetes': ['Metformin', 'Glibenclamide', 'Insulin Lantus', 'Insulin NovoRapid',
                 'Januvia', 'Glucophage', 'Amaryl'],
    'Pain Relief': ['Paracetamol', 'Ibuprofen', 'Diclofenac', 'Ketoprofen',
                    'Panadol', 'Voltaren', 'Celebrex'],
    'Respiratory': ['Salbutamol Inhaler', 'Ventolin', 'Seretide', 'Symbicort',
                    'Montelukast', 'Prednisolone', 'Budesonide'],
    'Gastrointestinal': ['Omeprazole', 'Ranitidine', 'Antodine', 'Motilium',
                         'Imodium', 'Lactulose', 'Gaviscon'],
    'Vitamins': ['Vitamin D', 'Vitamin B12', 'Folic Acid', 'Multivitamin',
                 'Calcium', 'Iron', 'Zinc'],
    'Dermatology': ['Hydrocortisone', 'Betnovate', 'Clotrimazole', 'Fusidic Acid',
                    'Betadine', 'Acne Cream'],
    'Neurological': ['Carbamazepine', 'Gabapentin', 'Fluoxetine', 'Sertraline',
                     'Alprazolam', 'Lexotanil'],
    'Pediatric': ['Pediatric Paracetamol', 'Amoxil Syrup', 'Cough Syrup',
                  'Gripe Water', 'Oral Rehydration']}

medications_data = []
med_id = 1

for category in categories:
    base_names = med_names.get(category, ['Generic Med'])

    # Generate multiple variants per category
    for _ in range(N_MEDICATIONS // len(categories)):
        name = random.choice(base_names)

        # Add dosage variants
        if category in ['Antibiotics', 'Pain Relief', 'Cardiovascular']:
            dosages = ['250mg', '500mg', '100mg', '50mg', '10mg', '5mg']
            name = f"{name} {random.choice(dosages)}"

        cost = round(random.uniform(5, 300), 2)
        markup = random.uniform(1.15, 1.6)  # 15-60% markup
        price = round(cost * markup, 2)

        medications_data.append({
            'medication_id': med_id,
            'medication_name': name,
            'category': category,
            'manufacturer': random.choice(manufacturers),
            'unit_cost': cost,
            'unit_price': price,
            'requires_rx': np.random.choice([True, False], p=[0.6, 0.4]),
            'expiry_months': random.choice([12, 18, 24, 36])
        })

        med_id += 1

        if med_id > N_MEDICATIONS:
            break

    if med_id > N_MEDICATIONS:
        break

medications_df = pd.DataFrame(medications_data)
print(f"✓ Created {len(medications_df)} medications across {len(categories)} categories")

# =====================================================================
# TABLE 3: EMPLOYEES
# =====================================================================

print("\n[3/7] Generating EMPLOYEES")

positions = ['Pharmacist', 'Assistant Pharmacist', 'Cashier', 'Manager', 'Inventory Clerk']
position_salaries = {
    'Pharmacist': (8000, 15000),
    'Assistant Pharmacist': (5000, 9000),
    'Cashier': (3500, 6000),
    'Manager': (12000, 20000),
    'Inventory Clerk': (4000, 7000)
}

employees_data = []
for i in range(1, N_EMPLOYEES + 1):
    position = random.choice(positions)
    salary_range = position_salaries[position]

    employees_data.append({
        'employee_id': i,
        'employee_name': f'Employee_{i:03d}',
        'branch_id': random.randint(1, N_BRANCHES),
        'position': position,
        'hire_date': (DATE_START - timedelta(days=random.randint(30, 1095))).date(),
        'salary': random.randint(salary_range[0], salary_range[1])
    })

employees_df = pd.DataFrame(employees_data)
print(f"✓ Created {len(employees_df)} employees")

# =====================================================================
# TABLE 4: SALES (50,000 transactions)
# =====================================================================

print("\n[4/7] Generating SALES (this will take a minute)")

payment_methods = ['Cash', 'Card', 'Insurance']
age_groups = ['Child', 'Adult', 'Senior']

category_weights = {
    'Pain Relief': 0.20,
    'Vitamins': 0.15,
    'Respiratory': 0.12,
    'Gastrointestinal': 0.12,
    'Antibiotics': 0.10,
    'Cardiovascular': 0.10,
    'Diabetes': 0.08,
    'Dermatology': 0.06,
    'Pediatric': 0.04,
    'Neurological': 0.03}

sales_data = []
for i in range(1, N_SALES + 1):
    sale_date = DATE_START + timedelta(days=random.randint(0, (DATE_END - DATE_START).days))

    category = random.choices(list(category_weights.keys()),
                              weights=list(category_weights.values()))[0]
    med = medications_df[medications_df['category'] == category].sample(1).iloc[0]

    qty = random.choices([1, 2, 3, 4, 5], weights=[0.5, 0.3, 0.12, 0.05, 0.03])[0]

    sale_time = f"{random.randint(9, 21):02d}:{random.randint(0, 59):02d}:00"

    sales_data.append({
        'sale_id': i,
        'branch_id': random.randint(1, N_BRANCHES),
        'employee_id': random.randint(1, N_EMPLOYEES),
        'medication_id': med['medication_id'],
        'sale_date': sale_date.date(),
        'sale_time': sale_time,
        'quantity': qty,
        'unit_price': med['unit_price'],
        'total_amount': round(qty * med['unit_price'], 2),
        'payment_method': random.choice(payment_methods),
        'customer_age_group': random.choice(age_groups)
    })

    if i % 10000 == 0:
        print(f"Progress: {i:,} / {N_SALES:,} sales generated")

sales_df = pd.DataFrame(sales_data)
print(f"✓ Created {len(sales_df):,} sales transactions")

# =====================================================================
# TABLE 5: INVENTORY
# =====================================================================

print("\n[5/7] Generating INVENTORY")

inventory_data = []
inv_id = 1

for branch in range(1, N_BRANCHES + 1):
    n_meds = random.randint(50, 80)
    stocked_meds = medications_df.sample(n=n_meds)

    for _, med in stocked_meds.iterrows():
        stock = random.choices(
            [0, random.randint(1, 10), random.randint(11, 50), random.randint(51, 300)],
            weights=[0.05, 0.15, 0.40, 0.40]
        )[0]

        last_restock = datetime.now() - timedelta(days=random.randint(1, 90))
        expiry = datetime.now() + timedelta(days=random.randint(30, med['expiry_months'] * 30))

        inventory_data.append({
            'inventory_id': inv_id,
            'branch_id': branch,
            'medication_id': med['medication_id'],
            'stock_quantity': stock,
            'last_restock': last_restock.date(),
            'expiry_date': expiry.date()
        })

        inv_id += 1

inventory_df = pd.DataFrame(inventory_data)
print(f"✓ Created {len(inventory_df)} inventory records")

# =====================================================================
# TABLE 6: SUPPLIERS
# =====================================================================

print("\n[6/7] Generating SUPPLIERS")

supplier_names = [
    'MedSupply Egypt', 'PharmaDist Cairo', 'HealthCare Suppliers',
    'MediLink Egypt', 'PharmaHub', 'Cairo Medical Distributors',
    'Alexandria Pharma Supplies', 'Delta Medical', 'Egyptian HealthCare Co.',
    'Nile Pharmaceuticals']

suppliers_data = []
for i in range(1, N_SUPPLIERS + 1):
    suppliers_data.append({
        'supplier_id': i,
        'supplier_name': supplier_names[i - 1],
        'contact_person': f'Contact_{i}',
        'phone': f'0{random.randint(10, 15)}{random.randint(10000000, 99999999)}',
        'email': f'supplier{i}@example.com',
        'city': random.choice(['Cairo', 'Alexandria', 'Giza', 'Tanta'])
    })

suppliers_df = pd.DataFrame(suppliers_data)
print(f"✓ Created {len(suppliers_df)} suppliers")

# =====================================================================
# TABLE 7: PURCHASE_ORDERS
# =====================================================================

print("\n[7/7] Generating PURCHASE_ORDERS")

purchase_orders_data = []
for i in range(1, N_PURCHASE_ORDERS + 1):
    order_date = DATE_START + timedelta(days=random.randint(0, (DATE_END - DATE_START).days))
    delivery_date = order_date + timedelta(days=random.randint(3, 14))

    med = medications_df.sample(1).iloc[0]
    qty = random.randint(50, 500)

    purchase_orders_data.append({
        'order_id': i,
        'branch_id': random.randint(1, N_BRANCHES),
        'supplier_id': random.randint(1, N_SUPPLIERS),
        'medication_id': med['medication_id'],
        'order_date': order_date.date(),
        'quantity': qty,
        'unit_cost': med['unit_cost'],
        'total_cost': round(qty * med['unit_cost'], 2),
        'delivery_date': delivery_date.date()
    })

purchase_orders_df = pd.DataFrame(purchase_orders_data)
print(f"   ✓ Created {len(purchase_orders_df)} purchase orders")

# =====================================================================
# EXPORT TO CSV
# =====================================================================

print("  EXPORTING DATA TO CSV")

branches_df.to_csv('branches.csv', index=False)
print("✓ branches.csv")

medications_df.to_csv('medications.csv', index=False)
print("✓ medications.csv")

employees_df.to_csv('employees.csv', index=False)
print("✓ employees.csv")

sales_df.to_csv('sales.csv', index=False)
print("✓ sales.csv")

inventory_df.to_csv('inventory.csv', index=False)
print("✓ inventory.csv")

suppliers_df.to_csv('suppliers.csv', index=False)
print("✓ suppliers.csv")

purchase_orders_df.to_csv('purchase_orders.csv', index=False)
print("✓ purchase_orders.csv")

# =====================================================================
# SUMMARY STATISTICS
# =====================================================================
print("  DATA GENERATION COMPLETE — SUMMARY")

print(f"""
Dataset Statistics:
  Branches          : {len(branches_df):>6,}
  Medications       : {len(medications_df):>6,}
  Employees         : {len(employees_df):>6,}
  Sales Transactions: {len(sales_df):>6,}
  Inventory Records : {len(inventory_df):>6,}
  Suppliers         : {len(suppliers_df):>6,}
  Purchase Orders   : {len(purchase_orders_df):>6,}

Time Period:
  Start Date        : {DATE_START.date()}
  End Date          : {DATE_END.date()}
  Duration          : {(DATE_END - DATE_START).days} days

Total Revenue:
  {sales_df['total_amount'].sum():,.2f} EGP

Ready for SQL import!
""")