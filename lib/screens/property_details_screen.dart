import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import '../models/property_model.dart';
import 'tour_scheduling_screen.dart'; 
import 'rating_review_screen.dart'; // Ensure this file exists in your project

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  
  // Get the current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid; 
  
  bool _isWishlisted = false;
  String _sellerName = 'Loading seller info...';
  // State to track if the property is currently sold (updated from model)
  bool _isSold = false; 
  
  // Flagging State Variables
  bool _isFlaggedByCurrentUser = false; 
  int _currentFlagCount = 0; 
  static const int _FLAG_THRESHOLD = 5; 
  bool _isFlagging = false;
  bool _isMarkingSold = false; 

  @override
  void initState() {
    super.initState();
    _isSold = widget.property.isSold ?? false; 
    
    if (_userId != null) {
      _checkWishlistStatus();
      _checkFlagStatus(); 
    }
    _fetchSellerInfo(); 
  }
  
  // --- Data Fetching Methods ---

  Future<void> _fetchSellerInfo() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.property.sellerId).get();
      final data = doc.data();
      if (mounted) {
        setState(() {
          _sellerName = data?['name'] ?? 'Unknown Seller';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sellerName = 'Error loading name';
        });
      }
    }
  }

  Future<void> _checkFlagStatus() async {
    if (_userId == null) return;

    try {
      final propertyDoc = _firestore.collection('listings').doc(widget.property.id);
      
      propertyDoc.snapshots().listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _currentFlagCount = snapshot.data()?['flagCount'] ?? 0;
            _isSold = snapshot.data()?['isSold'] ?? false; 
          });
        }
      });
      
      final userFlagDoc = await propertyDoc.collection('flags').doc(_userId!).get();
      
      if (mounted) {
        setState(() {
          _isFlaggedByCurrentUser = userFlagDoc.exists;
        });
      }
    } catch (e) {
      print('Error checking flag status: $e');
    }
  }

  Future<void> _checkWishlistStatus() async {
    if (_userId == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('wishlist')
          .doc(widget.property.id)
          .get();
      if (mounted) {
        setState(() {
          _isWishlisted = doc.exists;
        });
      }
    } catch (e) {
      print('Error checking wishlist status: $e');
    }
  }

  // --- Action Methods ---

  Future<void> _toggleWishlist() async {
    if (_userId == null) {
       _showSnackbar('Please log in to manage your wishlist.', Colors.orange);
       return;
    }
    
    final wishlistRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('wishlist')
        .doc(widget.property.id);

    try {
      if (_isWishlisted) {
        await wishlistRef.delete();
        _showSnackbar('Removed from Wishlist', Colors.red);
      } else {
        await wishlistRef.set({}); 
        _showSnackbar('Added to Wishlist!', Colors.green);
      }
      if (mounted) {
        setState(() {
          _isWishlisted = !_isWishlisted;
        });
      }
    } catch (e) {
      _showSnackbar('Failed to update wishlist.', Colors.red);
    }
  }
  
  Future<void> _toggleFlagProperty() async {
    if (_userId == null) {
      _showSnackbar('Please log in to flag a property.', Colors.orange);
      return;
    }
    if (_isFlagging) return;

    setState(() { _isFlagging = true; });

    final propertyRef = _firestore.collection('listings').doc(widget.property.id);
    final flagRef = propertyRef.collection('flags').doc(_userId!);
    
    try {
      if (_isFlaggedByCurrentUser) {
        await _firestore.runTransaction((transaction) async {
          transaction.delete(flagRef);
          transaction.update(propertyRef, {'flagCount': FieldValue.increment(-1)});
        });
        _showSnackbar('Property unflagged.', Colors.green);
      } else {
        await _firestore.runTransaction((transaction) async {
          transaction.set(flagRef, {'timestamp': FieldValue.serverTimestamp()});
          transaction.update(propertyRef, {'flagCount': FieldValue.increment(1)});
        });
        _showSnackbar('Property flagged for review.', Colors.red);
      }
      
      if (mounted) {
        setState(() {
          _isFlaggedByCurrentUser = !_isFlaggedByCurrentUser;
        });
      }
    } catch (e) {
      _showSnackbar('Failed to update flag status.', Colors.red);
    } finally {
      if (mounted) {
        setState(() { _isFlagging = false; });
      }
    }
  }
  
  Future<void> _markPropertyAsSold() async {
    if (_userId == null || _userId != widget.property.sellerId) {
      _showSnackbar('You are not authorized to mark this property as sold.', Colors.red);
      return;
    }
    if (_isSold) return;
    if (_isMarkingSold) return;
    
    final bool confirm = await _showConfirmDialog(
      'Confirm Sale', 
      'Are you sure you want to mark this property as SOLD?'
    ) ?? false;

    if (!confirm) return;

    setState(() { _isMarkingSold = true; });

    final propertyRef = _firestore.collection('listings').doc(widget.property.id);
    final transactionHistoryRef = _firestore.collection('users').doc(_userId).collection('transactions');
    final Timestamp saleTimestamp = Timestamp.now();

    try {
      final batch = _firestore.batch();
      batch.update(propertyRef, {
        'isSold': true,
        'saleTimestamp': saleTimestamp,
        'soldToId': 'Completed Sale', 
      });
      
      batch.set(transactionHistoryRef.doc(), {
        'propertyId': widget.property.id,
        'title': widget.property.title,
        'price': widget.property.price,
        'saleType': 'Sold',
        'date': saleTimestamp,
      });
      
      await batch.commit();
      _showSnackbar('Property marked as SOLD successfully!', Colors.green);
      
      if (mounted) {
        setState(() {
          _isSold = true; 
        });
      }
    } catch (e) {
      _showSnackbar('Failed to mark property as sold.', Colors.red);
    } finally {
      if (mounted) {
        setState(() { _isMarkingSold = false; });
      }
    }
  }

  // --- Utility ---
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }
  
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
          ],
        );
      },
    );
  }

  // --- UI Building Blocks ---

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Ratings and Reviews List UI ---
  Widget _buildReviewSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('listings')
          .doc(widget.property.id)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("No reviews yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }

        final reviews = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;
            final double reviewRating = (data['rating'] ?? 0).toDouble();
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Row(
                  children: List.generate(5, (i) => Icon(
                    i < reviewRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  )),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(data['review'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 5),
                    Text("By: ${data['userEmail'] ?? 'Anonymous'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFlagStatus() {
    final bool isHighlyFlagged = _currentFlagCount >= _FLAG_THRESHOLD;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(isHighlyFlagged ? Icons.warning : Icons.flag, 
                     color: isHighlyFlagged ? Colors.red.shade700 : Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                Text(isHighlyFlagged ? 'High Flag Count!' : 'Flag Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, 
                    color: isHighlyFlagged ? Colors.red.shade700 : Colors.black87)),
              ],
            ),
            Text('Count: $_currentFlagCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSold ? null : (_userId != null ? _toggleFlagProperty : () => _showSnackbar('Please log in.', Colors.orange)),
            icon: Icon(_isFlaggedByCurrentUser ? Icons.flag_outlined : Icons.flag),
            label: Text(_isFlagging ? 'Updating...' : (_isFlaggedByCurrentUser ? 'Unflag' : 'Flag for Review')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFlaggedByCurrentUser ? Colors.orange.shade200 : Colors.red.shade100,
              foregroundColor: _isFlaggedByCurrentUser ? Colors.orange.shade900 : Colors.red.shade900,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSoldOutBanner() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white, width: 3)),
            child: const Text('SOLD OUT', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4)),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomActionButton(ThemeData theme) {
    if (_isSold) {
      return SizedBox(
        height: 55,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline, size: 24),
          label: const Text('Property SOLD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade400, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      );
    }
    
    final isSeller = _userId != null && _userId == widget.property.sellerId;
    if (isSeller) {
      return SizedBox(
        height: 55,
        child: ElevatedButton.icon(
          onPressed: _isMarkingSold ? null : _markPropertyAsSold,
          icon: _isMarkingSold ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.money_off, size: 24),
          label: Text(_isMarkingSold ? 'Processing...' : 'Mark as SOLD', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      );
    }
    
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TourSchedulingScreen(propertyId: widget.property.id, propertyTitle: widget.property.title, sellerId: widget.property.sellerId))),
        icon: const Icon(Icons.calendar_month, size: 24),
        label: const Text('Schedule Virtual Tour', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImageUrl = widget.property.imageUrl != null && widget.property.imageUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.title),
        actions: [
          if (!_isSold) IconButton(icon: Icon(_isWishlisted ? Icons.favorite : Icons.favorite_border, color: _isWishlisted ? Colors.red : Colors.grey.shade700), onPressed: _toggleWishlist),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'property-image-${widget.property.id}',
              child: Stack(
                children: [
                  Container(
                    height: 250, width: double.infinity,
                    decoration: BoxDecoration(image: hasImageUrl ? DecorationImage(image: NetworkImage(widget.property.imageUrl!), fit: BoxFit.cover) : null, color: Colors.grey.shade200),
                    child: !hasImageUrl ? const Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey)) : null,
                  ),
                  if (_isSold) _buildSoldOutBanner(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${widget.property.price}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _isSold ? Colors.grey : theme.primaryColor, decoration: _isSold ? TextDecoration.lineThrough : TextDecoration.none)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _isSold ? Colors.grey.withOpacity(0.1) : theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(widget.property.type, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isSold ? Colors.grey.shade700 : theme.primaryColor)),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.person_pin_circle, 'Listed By', '$_sellerName'),
                  _buildDetailRow(Icons.location_on, 'Address', widget.property.address),
                  _buildDetailRow(Icons.date_range, _isSold ? 'Date Sold' : 'Date Listed', (_isSold ? (widget.property.saleTimestamp ?? Timestamp.now()) : widget.property.timestamp).toDate().toString().split(' ')[0]),
                  const Divider(height: 30),
                  const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(widget.property.description, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54)),
                  const Divider(height: 30),

                  // --- NEW: RATINGS & REVIEWS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ratings & Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if (_userId != null && _userId != widget.property.sellerId) 
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => RatingReviewScreen(propertyId: widget.property.id))
                          ),
                          icon: const Icon(Icons.rate_review),
                          label: const Text("Rate Now"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildReviewSection(),
                  const Divider(height: 30),

                  if (!_isSold) ...[
                    _buildFlagStatus(),
                    const Divider(height: 30),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBottomActionButton(theme),
        ),
      ),
    );
  }
}