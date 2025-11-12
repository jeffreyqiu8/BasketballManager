import 'package:flutter/material.dart';
import '../../gameData/save_creation_data.dart';

/// Widget for configuring game difficulty settings
class DifficultySettingsWidget extends StatefulWidget {
  final DifficultySettings difficulty;
  final Function(DifficultySettings) onDifficultyChanged;

  const DifficultySettingsWidget({
    super.key,
    required this.difficulty,
    required this.onDifficultyChanged,
  });

  @override
  State<DifficultySettingsWidget> createState() => _DifficultySettingsWidgetState();
}

class _DifficultySettingsWidgetState extends State<DifficultySettingsWidget> {
  late DifficultySettings _currentDifficulty;

  @override
  void initState() {
    super.initState();
    _currentDifficulty = widget.difficulty;
  }

  void _updateDifficulty() {
    widget.onDifficultyChanged(_currentDifficulty);
  }

  void _onPresetChanged(DifficultyLevel level) {
    setState(() {
      switch (level) {
        case DifficultyLevel.easy:
          _currentDifficulty = DifficultySettings.easy();
          break;
        case DifficultyLevel.normal:
          _currentDifficulty = DifficultySettings.normal();
          break;
        case DifficultyLevel.hard:
          _currentDifficulty = DifficultySettings.hard();
          break;
      }
    });
    _updateDifficulty();
  }

  void _onPlayerDevelopmentRateChanged(double rate) {
    setState(() {
      _currentDifficulty = DifficultySettings(
        level: _currentDifficulty.level,
        playerDevelopmentRate: rate,
        injuryRate: _currentDifficulty.injuryRate,
        tradeAIAggressiveness: _currentDifficulty.tradeAIAggressiveness,
        enableSalaryCap: _currentDifficulty.enableSalaryCap,
        enableDraftLottery: _currentDifficulty.enableDraftLottery,
      );
    });
    _updateDifficulty();
  }

  void _onInjuryRateChanged(double rate) {
    setState(() {
      _currentDifficulty = DifficultySettings(
        level: _currentDifficulty.level,
        playerDevelopmentRate: _currentDifficulty.playerDevelopmentRate,
        injuryRate: rate,
        tradeAIAggressiveness: _currentDifficulty.tradeAIAggressiveness,
        enableSalaryCap: _currentDifficulty.enableSalaryCap,
        enableDraftLottery: _currentDifficulty.enableDraftLottery,
      );
    });
    _updateDifficulty();
  }

  void _onTradeAIAggressivenessChanged(double aggressiveness) {
    setState(() {
      _currentDifficulty = DifficultySettings(
        level: _currentDifficulty.level,
        playerDevelopmentRate: _currentDifficulty.playerDevelopmentRate,
        injuryRate: _currentDifficulty.injuryRate,
        tradeAIAggressiveness: aggressiveness,
        enableSalaryCap: _currentDifficulty.enableSalaryCap,
        enableDraftLottery: _currentDifficulty.enableDraftLottery,
      );
    });
    _updateDifficulty();
  }

  void _onSalaryCapChanged(bool enabled) {
    setState(() {
      _currentDifficulty = DifficultySettings(
        level: _currentDifficulty.level,
        playerDevelopmentRate: _currentDifficulty.playerDevelopmentRate,
        injuryRate: _currentDifficulty.injuryRate,
        tradeAIAggressiveness: _currentDifficulty.tradeAIAggressiveness,
        enableSalaryCap: enabled,
        enableDraftLottery: _currentDifficulty.enableDraftLottery,
      );
    });
    _updateDifficulty();
  }

  void _onDraftLotteryChanged(bool enabled) {
    setState(() {
      _currentDifficulty = DifficultySettings(
        level: _currentDifficulty.level,
        playerDevelopmentRate: _currentDifficulty.playerDevelopmentRate,
        injuryRate: _currentDifficulty.injuryRate,
        tradeAIAggressiveness: _currentDifficulty.tradeAIAggressiveness,
        enableSalaryCap: _currentDifficulty.enableSalaryCap,
        enableDraftLottery: enabled,
      );
    });
    _updateDifficulty();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difficulty Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Difficulty presets
                  Text(
                    'Difficulty Presets',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a preset or customize individual settings below',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Difficulty preset cards
                  ...DifficultyLevel.values.map((level) {
                    final isSelected = _currentDifficulty.level == level;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _onPresetChanged(level),
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
                                _getDifficultyIcon(level),
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
                                      level.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected 
                                            ? Theme.of(context).primaryColor 
                                            : null,
                                      ),
                                    ),
                                    Text(
                                      level.description,
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
                  
                  const SizedBox(height: 32),
                  
                  // Custom settings
                  Text(
                    'Custom Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Player development rate
                  _buildSliderSetting(
                    'Player Development Rate',
                    _currentDifficulty.playerDevelopmentRate,
                    0.5,
                    2.0,
                    _onPlayerDevelopmentRateChanged,
                    'How quickly players improve their skills',
                    '${(_currentDifficulty.playerDevelopmentRate * 100).round()}%',
                  ),
                  
                  // Injury rate
                  _buildSliderSetting(
                    'Injury Rate',
                    _currentDifficulty.injuryRate,
                    0.0,
                    0.3,
                    _onInjuryRateChanged,
                    'Frequency of player injuries during games',
                    '${(_currentDifficulty.injuryRate * 100).round()}%',
                  ),
                  
                  // Trade AI aggressiveness
                  _buildSliderSetting(
                    'AI Trade Aggressiveness',
                    _currentDifficulty.tradeAIAggressiveness,
                    0.1,
                    1.0,
                    _onTradeAIAggressivenessChanged,
                    'How actively AI teams pursue trades',
                    '${(_currentDifficulty.tradeAIAggressiveness * 100).round()}%',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Game features
                  Text(
                    'Game Features',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Salary cap toggle
                  SwitchListTile(
                    title: const Text('Enable Salary Cap'),
                    subtitle: const Text('Enforce team salary limitations'),
                    value: _currentDifficulty.enableSalaryCap,
                    onChanged: _onSalaryCapChanged,
                  ),
                  
                  // Draft lottery toggle
                  SwitchListTile(
                    title: const Text('Enable Draft Lottery'),
                    subtitle: const Text('Use lottery system for draft order'),
                    value: _currentDifficulty.enableDraftLottery,
                    onChanged: _onDraftLotteryChanged,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Difficulty summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Difficulty Summary',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryItem(
                            'Overall Difficulty',
                            _currentDifficulty.level.displayName,
                          ),
                          _buildSummaryItem(
                            'Player Development',
                            '${(_currentDifficulty.playerDevelopmentRate * 100).round()}% speed',
                          ),
                          _buildSummaryItem(
                            'Injury Frequency',
                            '${(_currentDifficulty.injuryRate * 100).round()}% chance',
                          ),
                          _buildSummaryItem(
                            'AI Competition',
                            '${(_currentDifficulty.tradeAIAggressiveness * 100).round()}% aggressive',
                          ),
                          _buildSummaryItem(
                            'Salary Cap',
                            _currentDifficulty.enableSalaryCap ? 'Enabled' : 'Disabled',
                          ),
                          _buildSummaryItem(
                            'Draft Lottery',
                            _currentDifficulty.enableDraftLottery ? 'Enabled' : 'Disabled',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recommendation card
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recommendation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const Text(
                                  'New players should start with Normal difficulty for the best balance of challenge and enjoyment.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
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

  Widget _buildSliderSetting(
    String title,
    double currentValue,
    double min,
    double max,
    Function(double) onChanged,
    String description,
    String displayValue,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                displayValue,
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
            value: currentValue,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getDifficultyIcon(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return Icons.sentiment_satisfied;
      case DifficultyLevel.normal:
        return Icons.sentiment_neutral;
      case DifficultyLevel.hard:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}