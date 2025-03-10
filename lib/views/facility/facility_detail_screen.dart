// lib/views/facility/facility_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/sport_model.dart';
import '../../models/facility_model.dart';

class FacilityDetailScreen extends StatelessWidget {
  final SportFacilityModel facility;
  final List<SportModel> sports;

  const FacilityDetailScreen({
    Key? key,
    required this.facility,
    required this.sports,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar avec image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                facility.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  facility.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: facility.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.sports,
                              size: 80,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.sports,
                            size: 80,
                            color: Colors.grey.shade700,
                          ),
                        ),
                  // Superposition de gradient pour assurer la lisibilité du titre
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adresse avec bouton pour ouvrir Maps
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          facility.address,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.directions),
                        onPressed: () async {
                          final url =
                              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(facility.address)}';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        tooltip: 'Itinéraire',
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Horaires
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.access_time, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Horaires',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              facility.openingHours ??
                                  'Horaires non disponibles',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tarifs
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.euro, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tarifs',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              facility.priceRange ?? 'Tarifs non disponibles',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sports disponibles
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sports, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sports disponibles',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: facility.sportIds.map((sportId) {
                                final sport = sports.firstWhere(
                                  (s) => s.id == sportId,
                                  orElse: () => SportModel(
                                      id: sportId, name: 'Sport $sportId'),
                                );
                                return Chip(
                                  label: Text(sport.name),
                                  backgroundColor: Colors.blue.shade100,
                                  labelStyle: TextStyle(
                                    color: Colors.blue.shade800,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Description
                  if (facility.description != null &&
                      facility.description!.isNotEmpty) ...[
                    const Text(
                      'À propos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      facility.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Liens et contacts
                  const Text(
                    'Contact',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Téléphone
                  if (facility.phone != null)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(Icons.phone, color: Colors.green.shade700),
                      ),
                      title: const Text('Téléphone'),
                      subtitle: Text(facility.phone!),
                      onTap: () async {
                        final url = 'tel:${facility.phone}';
                        if (await canLaunch(url)) {
                          await launch(url);
                        }
                      },
                    ),

                  // Site web
                  if (facility.website != null)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child:
                            Icon(Icons.language, color: Colors.blue.shade700),
                      ),
                      title: const Text('Site web'),
                      subtitle: Text(facility.website!),
                      onTap: () async {
                        if (await canLaunch(facility.website!)) {
                          await launch(facility.website!);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Prix
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tarif',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    facility.priceRange ?? 'Non disponible',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // Bouton de réservation ou contact
              ElevatedButton(
                onPressed: () async {
                  if (facility.phone != null) {
                    final url = 'tel:${facility.phone}';
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  } else if (facility.website != null) {
                    if (await canLaunch(facility.website!)) {
                      await launch(facility.website!);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Contacter / Réserver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
