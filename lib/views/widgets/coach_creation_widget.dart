import 'package:flutter/material.dart';
import '../../gameData/save_creation_data.dart';
import '../../gameData/enums.dart';

/// Widget for creating coach profile with specializations
class CoachCreationWidget extends StatefulWidget {
  final CoachCreationData coachData;
  final Function(CoachCreationData) onCoachDataChanged;

  const CoachCreationWidget({
    super.key,
    required this.coachData,
    required this.onCoachDataChanged,
  });

  @override
  State<CoachCreationWidget> createState() => _CoachCreationWidgetState();
}

class _CoachCreationWidgetState extends State<CoachCreationWidget> {
  final TextEditingController _nameController = TextEditingController();
  late CoachCreationData _currentData;

  @override
  void initState() {
    super.initState();
    _currentData = widget.coachData;
    _nameController.text = _currentData.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateCoachData() {
    widget.onCoachDataChanged(_currentData);
  }

  void _onNameChanged(String name) {
    setState(() {
      _currentData = CoachCreationData(
        name: name,
        appearance: _currentData.appearance,
        primarySpecialization: _currentData.primarySpecialization,
        secondarySpecialization: _currentData.secondarySpecialization,
        initialAttributes: _currentData.initialAttributes,
      );
    });
    _updateCoachData();
  }

  void _onPrimarySpecializationChanged(CoachingSpecialization specialization) {
    setState(() {
      _currentData = CoachCreationData(
        name: _currentData.name,
        appearance: _currentData.appearance,
        primarySpecialization: specialization,
        secondarySpecialization: _currentData.secondarySpecialization == specialization 
            ? null 
            : _currentData.secondarySpecialization,
        initialAttributes: _currentData.initialAttributes,
      );
    });
    _updateCoachData();
  }

  void _onSecondarySpecializationChanged(CoachingSpecialization? specialization) {
    setState(() {
      _currentData = CoachCreationData(
        name: _currentData.name,
        appearance: _currentData.appearance,
        primarySpecialization: _currentData.primarySpecialization,
        secondarySpecialization: specialization,
        initialAttributes: _currentData.initialAttributes,
      );
    });
    _updateCoachData();
  }

  void _onAttributeChanged(String attribute, int value) {
    setState(() {
      final newAttributes = Map<String, int>.from(_currentData.initialAttributes);
      newAttributes[attribute] = value;
      
      _currentData = CoachCreationData(
        name: _currentData.name,
        appearance: _currentData.appearance,
        primarySpecialization: _currentData.primarySpecialization,
        secondarySpecialization: _currentData.secondarySpecialization,
        initialAttributes: newAttributes,
      );
    });
    _updateCoachData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Your Coach',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Coach Name *',
                      hintText: 'Enter your coach\'s name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Coach name is required';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    onChanged: _onNameChanged,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Primary specialization
                  Text(
                    'Primary Specialization',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your coach\'s main area of expertise',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ...CoachingSpecialization.values.map((specialization) {
                    final isSelected = _currentData.primarySpecialization == specialization;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _onPrimarySpecializationChanged(specialization),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected 
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getSpecializationIcon(specialization),
                                color: isSelected 
                                    ? Theme.of(context).primaryColor 
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      specialization.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected 
                                            ? Theme.of(context).primaryColor 
                                            : null,
                                      ),
                                    ),
                                    Text(
                                      specialization.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Secondary specialization (optional)
                  Text(
                    'Secondary Specialization (Optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a secondary area of expertise for additional bonuses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<CoachingSpecialization?>(
                    value: _currentData.secondarySpecialization,
                    decoration: const InputDecoration(
                      labelText: 'Secondary Specialization',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add_circle_outline),
                    ),
                    items: [
                      const DropdownMenuItem<CoachingSpecialization?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...CoachingSpecialization.values
                          .where((spec) => spec != _currentData.primarySpecialization)
                          .map((specialization) => DropdownMenuItem(
                                value: specialization,
                                child: Text(specialization.displayName),
                              )),
                    ],
                    onChanged: _onSecondarySpecializationChanged,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Initial attributes
                  Text(
                    'Initial Coaching Attributes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distribute points across different coaching skills (200 total points)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._currentData.initialAttributes.entries.map((entry) {
                    return _buildAttributeSlider(
                      entry.key,
                      entry.value,
                      _getAttributeDisplayName(entry.key),
                      _getAttributeDescription(entry.key),
                    );
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Total points display
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Points Used:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${_getTotalPoints()} / 200',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _getTotalPoints() > 200 
                                  ? Colors.red 
                                  : Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSlider(String key, int value, String displayName, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value.toDouble(),
            min: 30,
            max: 80,
            divisions: 50,
            onChanged: (newValue) {
              _onAttributeChanged(key, newValue.round());
            },
          ),
        ],
      ),
    );
  }

  IconData _getSpecializationIcon(CoachingSpecialization specialization) {
    switch (specialization) {
      case CoachingSpecialization.offensive:
        return Icons.sports_basketball;
      case CoachingSpecialization.defensive:
        return Icons.shield;
      case CoachingSpecialization.playerDevelopment:
        return Icons.trending_up;
      case CoachingSpecialization.teamChemistry:
        return Icons.group;
    }
  }

  String _getAttributeDisplayName(String attribute) {
    switch (attribute) {
      case 'offensive':
        return 'Offensive Coaching';
      case 'defensive':
        return 'Defensive Coaching';
      case 'development':
        return 'Player Development';
      case 'chemistry':
        return 'Team Chemistry';
      default:
        return attribute;
    }
  }

  String _getAttributeDescription(String attribute) {
    switch (attribute) {
      case 'offensive':
        return 'Ability to design and execute offensive strategies';
      case 'defensive':
        return 'Skill in developing defensive schemes and tactics';
      case 'development':
        return 'Effectiveness in improving player skills and potential';
      case 'chemistry':
        return 'Talent for building team cohesion and morale';
      default:
        return 'Coaching attribute';
    }
  }

  int _getTotalPoints() {
    return _currentData.initialAttributes.values.fold(0, (sum, value) => sum + value);
  }
}