import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:iconsax/iconsax.dart';

Widget ratingResumen(
  String productoId, {
  Axis direction = Axis.horizontal,
  bool mostrarTexto = true,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0.0),
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productos')
          .doc(productoId)
          .collection('comentarios')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final comentarios = snapshot.data!.docs;

        // Calcular promedio
        double total = 0.0;
        for (var doc in comentarios) {
          final data = doc.data() as Map<String, dynamic>;
          final rating = (data['rating'] ?? 0.0) as num;
          total += rating.toDouble();
        }

        final double promedio =
            comentarios.isEmpty ? 0.0 : total / comentarios.length;

        final ratingBar = RatingBarIndicator(
          rating: promedio,
          itemBuilder: (context, _) => const Icon(
            Iconsax.star,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: 18.0,
          direction: direction,
          unratedColor: Theme.of(context).iconTheme.color?.withOpacity(0.3),
        );

        final ratingText = Text(
          "${promedio.toStringAsFixed(1)}",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
        );

        if (direction == Axis.horizontal) {
          return Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ratingBar,
                if (mostrarTexto) const SizedBox(width: 8),
                if (mostrarTexto) ratingText,
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mostrarTexto) ratingText,
                if (mostrarTexto) const SizedBox(height: 6),
                ratingBar,
              ],
            ),
          );
        }
      },
    ),
  );
}
