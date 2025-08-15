import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ImageCacheHelper {
  static String? profileImageUrl;
  static bool isImageLoaded = false;
  static void clearCache() {
    profileImageUrl = null;
    isImageLoaded = false;
  }
}

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final User? user;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.user,
  }) : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  String? firestoreProfileImageUrl;
  bool isImageLoaded = false;

  @override
  void initState() {
    super.initState();

    if (!ImageCacheHelper.isImageLoaded && widget.user != null) {
      getFirestoreProfileImageUrl(widget.user!.uid).then((url) {
        if (mounted) {
          setState(() {
            firestoreProfileImageUrl = url;
            isImageLoaded = true;

            // Cachearlo
            ImageCacheHelper.profileImageUrl = url;
            ImageCacheHelper.isImageLoaded = true;
          });
        }
      });
    } else {
      firestoreProfileImageUrl = ImageCacheHelper.profileImageUrl;
      isImageLoaded = true;
    }
  }

  Future<String?> getFirestoreProfileImageUrl(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final url = data['profileImageUrl'];
        if (url is String && url.isNotEmpty) {
          return url;
        }
      }
    } catch (e, stackTrace) {
      // Usa logging en lugar de print en apps reales
      print("Error obteniendo la URL de la imagen de Firestore: $e");
      print("StackTrace: $stackTrace");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    double imageSize = 13;
    bool isProfileSelected = widget.currentIndex == 3;

    return SizedBox(
      height: 56,
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        backgroundColor: theme.bottomAppBarTheme.color,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onBackground.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontSize: 0),
        unselectedLabelStyle: const TextStyle(fontSize: 0),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.home, size: 30.0),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.shopping_cart, size: 30.0),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.building, size: 30.0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: imageSize + 1,
              backgroundColor: isProfileSelected
                  ? colorScheme.primary
                  : colorScheme.onBackground.withOpacity(0.6),
              child: CircleAvatar(
                radius: imageSize,
                backgroundColor: theme.scaffoldBackgroundColor,
                child: isImageLoaded
                    ? (firestoreProfileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: firestoreProfileImageUrl!,
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              backgroundImage: imageProvider,
                              radius: imageSize,
                            ),
                            placeholder: (context, url) =>
                                CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              LucideIcons.user2,
                              size: 26.0,
                              color: colorScheme.onBackground,
                            ),
                          )
                        : (widget.user != null && widget.user!.photoURL != null
                            ? CachedNetworkImage(
                                imageUrl: widget.user!.photoURL!,
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  backgroundImage: imageProvider,
                                  radius: imageSize,
                                ),
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  LucideIcons.user2,
                                  size: 26.0,
                                  color: colorScheme.onBackground,
                                ),
                              )
                            : CircleAvatar(
                                radius: imageSize,
                                backgroundColor: theme.scaffoldBackgroundColor,
                                child: Icon(
                                  LucideIcons.user2,
                                  size: 26.0,
                                  color: colorScheme.onBackground,
                                ),
                              )))
                    : CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
              ),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
