# 🎉 Agro-Dealer Sales Upgrade - Complete Implementation Guide

## ✅ What's Being Implemented

**Agro-Dealer → Farmer/Cooperative Sales** with:
- ✅ Searchable list of registered farmers/cooperatives
- ✅ No manual name entry allowed
- ✅ Auto-update both inventories
- ✅ SMS notifications
- ✅ Purchase history tracking

---

## 📝 Files Already Modified

### ✅ **1. agro_dealer_sales_screen.dart** (Partial)
**Added:**
- Import statements for FirestoreService, SMSService, CooperativeModel
- State variables for cooperative list and search
- `_loadCooperatives()` method
- `_filterCooperatives()` search method

**Still Need:**
- Replace customer name/type fields with search UI
- Update submit method with inventory updates
- Add SMS notification

---

## 🔄 **UI Changes Needed**

### **Replace This Section** (lines 409-442):
```dart
// OLD: Manual text fields
TextFormField(
  controller: _customerNameController,
  decoration: InputDecoration(
    labelText: 'Customer Name',
  ),
),

DropdownButtonFormField<String>(
  value: _customerType,
  items: [
    DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
    DropdownMenuItem(value: 'cooperative', child: Text('Cooperative')),
  ],
),
```

### **With This:**
```dart
// NEW: Searchable registered user selector
// Search Field
TextField(
  controller: _searchController,
  decoration: InputDecoration(
    labelText: 'Search Farmer/Cooperative',
    hintText: 'Search by name or location...',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.search),
    suffixIcon: _searchController.text.isNotEmpty
        ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _filterCooperatives('');
            },
          )
        : null,
  ),
  onChanged: _filterCooperatives,
),
const SizedBox(height: 12),

// Selected Cooperative Display
if (_selectedCooperative != null)
  Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      border: Border.all(color: Colors.green),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCooperative!.cooperativeName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_selectedCooperative!.location.district}, ${_selectedCooperative!.location.sector}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 20),
          onPressed: () => setState(() => _selectedCooperative = null),
        ),
      ],
    ),
  ),
const SizedBox(height: 12),

// Filtered Results List
if (_searchController.text.isNotEmpty && _selectedCooperative == null)
  Container(
    height: 200,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: _isLoadingCustomers
        ? Center(child: CircularProgressIndicator())
        : _filteredCooperatives.isEmpty
            ? Center(
                child: Text(
                  'No farmers found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            : ListView.builder(
                itemCount: _filteredCooperatives.length,
                itemBuilder: (context, index) {
                  final coop = _filteredCooperatives[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.agriculture, color: Colors.green),
                    ),
                    title: Text(coop.cooperativeName),
                    subtitle: Text(
                      '${coop.location.district}, ${coop.location.sector}',
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() {
                        _selectedCooperative = coop;
                        _searchController.clear();
                      });
                    },
                  );
                },
              ),
  ),
const SizedBox(height: 16),
```

---

## 🔄 **Submit Method Changes**

### **Update `_submitSale()` method:**

```dart
Future<void> _submitSale() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_selectedCooperative == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a farmer/cooperative')),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final quantity = double.parse(_quantityController.text);
    final pricePerKg = double.parse(_priceController.text);
    final totalAmount = quantity * pricePerKg;
    final cooperative = _selectedCooperative!;

    // 1. Record the sale
    await FirebaseFirestore.instance.collection('agro_dealer_sales').add({
      'agroDealerId': widget.agroDealerId,
      'seedVariety': _selectedVariety,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'customerId': cooperative.userId,  // ✅ Linked to registered user
      'customerName': cooperative.cooperativeName,
      'customerType': 'cooperative',
      'saleDate': Timestamp.now(),
      'paymentStatus': _paymentStatus,
      'paymentMethod': 'cash',
    });

    // 2. Reduce dealer's inventory
    await _reduceAgroDealerInventory(
      dealerUserId: widget.agroDealerId,
      seedVariety: _selectedVariety,
      quantity: quantity,
    );

    // 3. Add to farmer's purchase history
    await _recordFarmerPurchase(
      farmerId: cooperative.userId,
      agroDealerId: widget.agroDealerId,
      seedVariety: _selectedVariety,
      quantity: quantity,
      pricePerKg: pricePerKg,
      totalAmount: totalAmount,
    );

    // 4. Send SMS to farmer
    if (cooperative.phone.isNotEmpty) {
      try {
        await SMSService().sendNotification(
          phoneNumber: cooperative.phone,
          title: 'Seed Purchase Recorded',
          body: 'You purchased $quantity kg of $_selectedVariety seeds '
                'for ${totalAmount.toStringAsFixed(0)} RWF. '
                'Check iTraceLink app for details.',
        );
        debugPrint('✅ SMS sent to farmer: ${cooperative.phone}');
      } catch (smsError) {
        debugPrint('⚠️ SMS failed: $smsError');
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale recorded! ${cooperative.cooperativeName}\'s purchase history updated.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    setState(() => _isSubmitting = false);
  }
}

// Helper methods
Future<void> _reduceAgroDealerInventory({
  required String dealerUserId,
  required String seedVariety,
  required double quantity,
}) async {
  final inventory = await FirebaseFirestore.instance
      .collection('agro_dealer_inventory')
      .where('agroDealerId', isEqualTo: dealerUserId)
      .where('seedVariety', isEqualTo: seedVariety)
      .get();

  if (inventory.docs.isNotEmpty) {
    final doc = inventory.docs.first;
    final currentQuantity = (doc.data()['quantity'] ?? 0).toDouble();
    final newQuantity = currentQuantity - quantity;

    if (newQuantity < 0) {
      throw Exception('Insufficient inventory! Only ${currentQuantity}kg available.');
    }

    await doc.reference.update({
      'quantity': newQuantity,
      'lastUpdated': Timestamp.now(),
      'status': newQuantity == 0 ? 'out_of_stock' : 'in_stock',
    });
  } else {
    throw Exception('Seed variety not found in inventory');
  }
}

Future<void> _recordFarmerPurchase({
  required String farmerId,
  required String agroDealerId,
  required String seedVariety,
  required double quantity,
  required double pricePerKg,
  required double totalAmount,
}) async {
  await FirebaseFirestore.instance.collection('farmer_purchases').add({
    'farmerId': farmerId,
    'agroDealerId': agroDealerId,
    'seedVariety': seedVariety,
    'quantity': quantity,
    'pricePerKg': pricePerKg,
    'totalAmount': totalAmount,
    'purchaseDate': Timestamp.now(),
    'paymentStatus': _paymentStatus,
    'source': 'agro_dealer_sale',
  });
}
```

---

## 🗃️ **New Database Collection**

### **farmer_purchases** (Auto-created)
```firestore
farmer_purchases/
  └─ {purchase_id}
      ├─ farmerId: "farmer123"  ← Linked to registered farmer
      ├─ agroDealerId: "dealer456"
      ├─ seedVariety: "RWB 1245"
      ├─ quantity: 50
      ├─ pricePerKg: 1200
      ├─ totalAmount: 60000
      ├─ purchaseDate: 2025-11-02T23:00:00
      ├─ paymentStatus: "completed"
      └─ source: "agro_dealer_sale"
```

---

## 📱 **User Experience**

### **For Agro-Dealers:**

**Before:**
```
1. Type customer name manually ❌
2. Select type (farmer/cooperative)
3. Risk of typos
4. No tracking
```

**After:**
```
1. Type to search: "Twit..." 
2. See list of matching farmers:
   - Twitezimbere Coop (Kigali, Gasabo)
   - Twitungure Farmers (Musanze, Muhoza)
3. Select farmer ✅
4. Record sale
5. ✅ Farmer notified via SMS
6. ✅ Both inventories updated
7. ✅ Purchase history created
```

### **For Farmers:**

**Receive:**
1. 📱 SMS: "You purchased 50 kg of RWB 1245 seeds for 60000 RWF..."
2. Purchase appears in their account automatically
3. Can view purchase history in app
4. Seed tracking from producer → dealer → them

---

## ✅ **Complete Flow**

```
Agro-Dealer Records Sale:
  ├─> Search "Twitezimbere"
  ├─> Select from list
  ├─> Enter quantity & price
  └─> Click "Record"

System Automatically:
  ├─> ✅ Records sale
  ├─> ✅ Reduces dealer's inventory
  ├─> ✅ Creates farmer's purchase record
  └─> ✅ Sends SMS to farmer

Farmer:
  ├─> 📱 Receives SMS
  ├─> Opens app
  └─> Sees purchase history updated!
```

---

## 🔒 **Benefits**

### **Data Integrity:**
- ✅ Only registered, verified farmers can be selected
- ✅ No fake names in system
- ✅ Complete traceability
- ✅ Linked records throughout supply chain

### **Inventory Management:**
- ✅ Automatic stock reduction
- ✅ Prevents overselling
- ✅ Real-time inventory tracking
- ✅ Low stock alerts possible

### **User Experience:**
- ✅ Easy search by name or location
- ✅ No typing errors
- ✅ Instant notifications
- ✅ Professional record-keeping

---

## 🚀 **Testing Checklist**

- [ ] Search for farmer by name
- [ ] Search for farmer by location
- [ ] Select farmer from list
- [ ] Record sale with sufficient inventory
- [ ] Verify dealer inventory reduced
- [ ] Verify farmer purchase record created
- [ ] Verify SMS sent to farmer
- [ ] Test insufficient inventory error
- [ ] Test without selecting farmer (should show error)
- [ ] Test search with no results

---

## 📊 **Supply Chain Progress**

```
✅ Seed Producer → Agro-Dealer (COMPLETE)
✅ Agro-Dealer → Farmer (COMPLETE - with this update)
🔄 Farmer → Aggregator (Next)
🔄 Aggregator → Institution (Next)
🔄 Dealer/Aggregator → Consumer (Next)
```

---

## 💡 **Next Steps**

After implementing this:
1. Test the complete flow
2. Verify SMS notifications work
3. Check inventory updates
4. Move to next link: Farmer → Aggregator

---

**Document Version**: 1.0  
**Status**: Implementation Guide Complete  
**Ready to Code**: YES! ✅
