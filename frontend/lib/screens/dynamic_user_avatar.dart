import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DynamicUserAvatar extends StatefulWidget {
  final String? uid;
  final String? handle;
  final double radius;
  final String fallbackLetter;

  const DynamicUserAvatar({
    super.key,
    this.uid,
    this.handle,
    this.radius = 20,
    required this.fallbackLetter,
  });

  @override
  State<DynamicUserAvatar> createState() => _DynamicUserAvatarState();
}

class _DynamicUserAvatarState extends State<DynamicUserAvatar> {
  String? _profilePicBase64;

  // Global static caches to share resolved data across instances and prevent redundant reads
  static final Map<String, String?> _profilePicCache = {}; // Cache: uid -> base64
  static final Map<String, String> _handleToUidCache = {}; // Cache: handle -> uid

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(covariant DynamicUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uid != oldWidget.uid || widget.handle != oldWidget.handle || widget.fallbackLetter != oldWidget.fallbackLetter) {
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    String? targetUid = widget.uid;
    String? targetHandle = widget.handle;

    if (targetUid == null && targetHandle == null) return;

    if (targetHandle != null) {
      targetHandle = targetHandle.replaceAll('@', '').trim();
    }

    // 1. Check cache for UID directly
    if (targetUid != null && _profilePicCache.containsKey(targetUid)) {
      if (mounted) {
        setState(() {
          _profilePicBase64 = _profilePicCache[targetUid];
        });
      }
      return;
    }

    // 2. Check cache for Handle -> UID
    if (targetHandle != null && _handleToUidCache.containsKey(targetHandle)) {
      final cachedUid = _handleToUidCache[targetHandle]!;
      if (_profilePicCache.containsKey(cachedUid)) {
        if (mounted) {
          setState(() {
            _profilePicBase64 = _profilePicCache[cachedUid];
          });
        }
        return;
      }
      targetUid = cachedUid;
    }

    if (!mounted) return;

    try {
      // 3. Resolve handle if UID is not known
      if (targetUid == null && targetHandle != null) {
        final usernameDoc = await FirebaseFirestore.instance
            .collection('usernames')
            .doc(targetHandle)
            .get();

        if (usernameDoc.exists) {
          targetUid = usernameDoc.data()?['uid'];
          if (targetUid != null) {
            _handleToUidCache[targetHandle] = targetUid;
          }
        }
      }

      // 4. Retrieve user document for the profile picture
      if (targetUid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          final pic = data?['profilePicture'];
          _profilePicCache[targetUid] = pic;
          if (mounted) {
            setState(() {
              _profilePicBase64 = pic;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading dynamic avatar for handle $targetHandle: $e');
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profilePicBase64 != null && _profilePicBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: widget.radius,
          backgroundImage: MemoryImage(base64Decode(_profilePicBase64!)),
        );
      } catch (e) {
        debugPrint('Failed to decode base64 profile picture: $e');
      }
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: const Color(0xFF00FF7F).withValues(alpha: 0.15),
      child: Text(
        widget.fallbackLetter.isNotEmpty ? widget.fallbackLetter[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          color: const Color(0xFF00FF7F),
          fontSize: widget.radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
