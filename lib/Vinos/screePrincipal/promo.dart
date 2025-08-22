import 'package:bootsup/Vista/EmpresaVista/PerfilEmpresa.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/VisitaPerfil.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:redacted/redacted.dart';

class BuscarPageVinos extends StatefulWidget {
  const BuscarPageVinos({super.key});

  @override
  _BuscarPageState createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarPageVinos> {
  List<Map<String, dynamic>> _empresas = [];
  bool _isRedacted = true;
  bool _showBottomBar = true;
  List<Map<String, dynamic>> _allEmpresas = [];
  TextEditingController _searchController = TextEditingController();

  Future<void> _fetchEmpresas() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('empresa').get();

      final empresas = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'userid': data['userid']?.toString() ?? '',
          'nombre': data['nombre']?.toString() ?? 'Nombre no disponible',
          'perfilEmpresa': data['perfilEmpresa']?.toString() ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allEmpresas = empresas;
          _empresas = List.from(_allEmpresas);
        });
      }

      debugPrint('Empresas cargadas: ${_empresas.length}');
    } catch (e) {
      debugPrint('Error al cargar empresas: $e');
    }
  }

  void _fetchAndRedactEmpresas() async {
    if (!mounted) return;
    setState(() {
      _isRedacted = true;
      _empresas = List.generate(
          0,
          (index) => {
                'userid': '',
                'nombre': '',
                'perfilEmpresa': '',
              });
    });

    final stopwatch = Stopwatch()..start();

    await _fetchEmpresas();

    final elapsed = stopwatch.elapsed;
    const minDuration = Duration(seconds: 1);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
    if (!mounted) return;
    setState(() {
      _isRedacted = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndRedactEmpresas();
    });
    _searchController.addListener(() {
      String query = _searchController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _empresas = List.from(_allEmpresas);
        } else {
          _empresas = _allEmpresas
              .where((empresa) =>
                  empresa['nombre'].toString().toLowerCase().contains(query))
              .toList();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is UserScrollNotification) {
              final direction = scrollNotification.direction;
              if (direction == ScrollDirection.forward && !_showBottomBar) {
                setState(() => _showBottomBar = true);
              } else if (direction == ScrollDirection.reverse &&
                  _showBottomBar) {
                setState(() => _showBottomBar = false);
              }
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                toolbarHeight: 60,
                title: Theme(
                  data: ThemeData(
                    textSelectionTheme: const TextSelectionThemeData(
                      selectionColor: Color(0xFFFFC800),
                      cursorColor: Colors.black,
                      selectionHandleColor: Colors.black,
                    ),
                  ),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.iconTheme.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontFamily: 'Afacad',
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Buscar empresa...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: 'Afacad',
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              if (_searchController.text.isNotEmpty) {
                                setState(() {
                                  _searchController.clear();
                                });
                              }
                            },
                            child: Icon(
                              Iconsax.close_circle,
                              size: 27,
                              color: theme.iconTheme.color,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final empresa = _empresas[index];
                      final nombre = empresa['nombre'] ?? 'Sin nombre';
                      final isCurrentUser = empresa['userid'] ==
                          FirebaseAuth.instance.currentUser?.uid;

                      final bool isDark =
                          Theme.of(context).brightness == Brightness.dark;

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color:
                              isDark ? const Color(0xFF1F1F1F) : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              child: ClipOval(
                                child: empresa['perfilEmpresa'] != null &&
                                        empresa['perfilEmpresa']!.isNotEmpty
                                    ? Image.network(
                                        empresa['perfilEmpresa']!,
                                        fit: BoxFit.cover,
                                        width: 84,
                                        height: 84,
                                        errorBuilder: (_, __, ___) =>
                                            Image.asset(
                                          'assets/images/empresa.png',
                                          fit: BoxFit.cover,
                                          width: 84,
                                          height: 84,
                                        ),
                                      ).redacted(
                                        context: context, redact: _isRedacted)
                                    : Image.asset(
                                        'assets/images/empresa.png',
                                        fit: BoxFit.cover,
                                        width: 84,
                                        height: 84,
                                      ).redacted(
                                        context: context, redact: _isRedacted),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Tooltip(
                              message: nombre,
                              child: Text(
                                nombre,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                              ).redacted(context: context, redact: _isRedacted),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: _isRedacted
                                  ? Container(
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ).redacted(context: context, redact: true)
                                  : TextButton.icon(
                                      icon: Icon(
                                        isCurrentUser
                                            ? Icons.verified_user
                                            : Icons.storefront,
                                        size: 18,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      label: Text(
                                        isCurrentUser ? 'Tú' : 'Visitar',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Afacad',
                                        ),
                                      ),
                                      onPressed: () {
                                        final currentUserId = FirebaseAuth
                                            .instance.currentUser?.uid;
                                        if (empresa['userid'] ==
                                            currentUserId) {
                                          navegarConSlideDerecha(
                                            context,
                                            EmpresaProfileScreen(),
                                          );
                                        } else {
                                          navegarConSlideDerecha(
                                            context,
                                            VisitaperfilScreem(
                                                empresa: empresa),
                                          );
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFFFFAF00)
                                            : Colors.black,
                                        foregroundColor: isDark
                                            ? Colors.black
                                            : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _empresas.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.89,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
