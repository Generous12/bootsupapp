import 'package:cloud_firestore/cloud_firestore.dart';

class Publicacion {
  final String id;
  final List<String> imagenes;
  final String descripcion;
  final DateTime fecha;
  final String userid;
  final String publicacionDeEmpresa;
  final Map<String, dynamic> imageRatio;

  Publicacion({
    required this.id,
    required this.imagenes,
    required this.descripcion,
    required this.fecha,
    required this.userid,
    required this.publicacionDeEmpresa,
    required this.imageRatio,
  });

  factory Publicacion.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Publicacion(
      id: doc.id,
      imagenes: List<String>.from(data['imagenes'] ?? []),
      descripcion: data['descripcion'] ?? '',
      fecha: (data['fecha'] != null)
          ? (data['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      userid: data['userid'] ?? '',
      publicacionDeEmpresa: data['publicacionDeEmpresa'] ?? '',
      imageRatio: data['imageRatio'] != null
          ? Map<String, dynamic>.from(data['imageRatio'])
          : {}, // en caso no exista
    );
  }
}
