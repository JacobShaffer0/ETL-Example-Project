INSERT INTO ref.mcc_categories (mcc, description, category)
VALUES 
    ('5000', 'Grocery Stores, Supermarkets', 'grocery'),
    ('5100', 'Service Stations (Gas)', 'gas'),
    ('5200', 'Eating Places, Restaurants', 'dining'),
    ('5300', 'Drug Stores and Pharmacies', 'pharmacy'),
    ('5400', 'Utilities - Electric, Gas, Water', 'utilities')
ON CONFLICT (mcc) DO UPDATE 
SET 
    description = EXCLUDED.description,
    category = EXCLUDED.category;