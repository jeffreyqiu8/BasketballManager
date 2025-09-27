import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/role_manager.dart';
import 'package:BasketballManager/gameData/enums.dart';
import '../widgets/accessible_widgets.dart';
import '../widgets/help_system.dart';
import '../widgets/user_feedback_system.dart';

class RoleAssignmentPage extends StatefulWidget {
  final EnhancedTeam team;
  final List<EnhancedPlayer> players;

  const RoleAssignmentPage({
    super.key,
    required this.team,
    required this.players,
  });

  @override
  State<RoleAssignmentPage> createState() => _RoleAssignmentPageState();
}

class _RoleAssignmentPageState extends State<RoleAssignmentPage> {
  late Map<PlayerRole, EnhancedPlayer?> _roleAssignments;
  late List<EnhancedPlayer> _availablePlayers;
  String _selectedTab = 'lineup'; // 'lineup', 'roles', 'optimization'
  EnhancedPlayer? _draggedPlayer;
  PlayerRole? _draggedFromRole;

  @override
  void initState() {
    super.initState();
    _roleAssignments = Map.from(widget.team.roleAssignments);
    _availablePlayers = widget.players.where((player) => 
      !_roleAssignments.values.contains(player)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          '${widget.team.name} Lineup',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          HelpButton(contextId: 'role_assignment'),
          FeedbackButton(feature: 'role_assignment'),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            onPressed: _optimizeLineup,
            tooltip: 'Auto-Optimize',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLineup,
            tooltip: 'Save Lineup',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Navigation
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _tabButton('Lineup', 'lineup')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Roles', 'roles')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Analysis', 'optimization')),
              ],
            ),
          ),
          
          // Lineup Validation Status
          _buildValidationStatus(),
          
          // Tab Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String value) {
    bool isSelected = _selectedTab == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
          ? const Color.fromARGB(255, 82, 50, 168)
          : const Color.fromARGB(255, 44, 44, 44),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildValidationStatus() {
    bool isValid = _isLineupValid();
    List<String> issues = _getLineupIssues();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid 
          ? Colors.green[400]?.withValues(alpha: 0.2)
          : Colors.red[400]?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green[400]! : Colors.red[400]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            color: isValid ? Colors.green[400] : Colors.red[400],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid 
                ? 'Lineup is valid and ready to play'
                : issues.join(', '),
              style: TextStyle(
                fontSize: 12,
                color: isValid ? Colors.green[400] : Colors.red[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'roles':
        return _buildRolesTab();
      case 'optimization':
        return _buildOptimizationTab();
      default:
        return _buildLineupTab();
    }
  }  
Widget _buildLineupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Starting Lineup Card
          _buildStartingLineupCard(),
          const SizedBox(height: 16),
          
          // Available Players Card
          _buildAvailablePlayersCard(),
        ],
      ),
    );
  }

  Widget _buildStartingLineupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Starting Lineup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Position Slots
          ...PlayerRole.values.map((role) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPositionSlot(role),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPositionSlot(PlayerRole role) {
    EnhancedPlayer? assignedPlayer = _roleAssignments[role];
    
    return DragTarget<EnhancedPlayer>(
      onWillAccept: (player) => player != null,
      onAccept: (player) {
        setState(() {
          // Remove player from previous assignment
          _roleAssignments.removeWhere((key, value) => value == player);
          
          // If there was a player in this slot, move them to available
          if (assignedPlayer != null) {
            _availablePlayers.add(assignedPlayer!);
          }
          
          // Assign new player to this role
          _roleAssignments[role] = player;
          _availablePlayers.remove(player);
          
          // Update player's primary role
          player.assignPrimaryRole(role);
        });
      },
      builder: (context, candidateData, rejectedData) {
        bool isHighlighted = candidateData.isNotEmpty;
        
        return Container(
          height: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHighlighted 
              ? Colors.blue[400]?.withValues(alpha: 0.3)
              : Colors.grey[800]?.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlighted 
                ? Colors.blue[400]! 
                : assignedPlayer != null 
                  ? _getRoleCompatibilityColor(assignedPlayer!, role)
                  : Colors.grey[600]!,
              width: 2,
            ),
          ),
          child: assignedPlayer != null 
            ? _buildAssignedPlayerTile(assignedPlayer!, role)
            : _buildEmptySlot(role),
        );
      },
    );
  }

  Widget _buildAssignedPlayerTile(EnhancedPlayer player, PlayerRole role) {
    double compatibility = player.calculateRoleCompatibility(role);
    Color compatibilityColor = _getRoleCompatibilityColor(player, role);
    
    return Draggable<EnhancedPlayer>(
      data: player,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: compatibilityColor,
                child: Text(
                  player.name[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[700]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[500]!, width: 2),
        ),
        child: const Center(
          child: Text(
            'Dragging...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
      onDragStarted: () {
        setState(() {
          _draggedPlayer = player;
          _draggedFromRole = role;
        });
      },
      onDragEnd: (details) {
        setState(() {
          _draggedPlayer = null;
          _draggedFromRole = null;
        });
      },
      child: Row(
        children: [
          // Position Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(role),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role.abbreviation,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Player Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: compatibilityColor,
            child: Text(
              player.name[0],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Age ${player.age} • OVR ${_calculateOverallRating(player).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          
          // Compatibility Indicator
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: compatibilityColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(compatibility * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                _getCompatibilityLabel(compatibility),
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(PlayerRole role) {
    return Row(
      children: [
        // Position Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(role),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            role.abbreviation,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Empty Slot Indicator
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                role.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                'Drag a player here',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        
        // Add Button
        IconButton(
          onPressed: () => _showPlayerSelectionDialog(role),
          icon: Icon(
            Icons.add_circle_outline,
            color: Colors.grey[400],
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailablePlayersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Available Players',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${_availablePlayers.length} players',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_availablePlayers.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All players assigned',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your starting lineup is complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_availablePlayers.take(10).map((player) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAvailablePlayerTile(player),
              );
            })),
          
          if (_availablePlayers.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing 10 of ${_availablePlayers.length} players',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlayerTile(EnhancedPlayer player) {
    PlayerRole bestRole = player.getBestRole();
    double bestCompatibility = player.calculateRoleCompatibility(bestRole);
    
    return Draggable<EnhancedPlayer>(
      data: player,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getRoleCompatibilityColor(player, bestRole),
                child: Text(
                  player.name[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[700]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[500]!, width: 1),
        ),
        child: const Center(
          child: Text(
            'Dragging...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Player Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleCompatibilityColor(player, bestRole),
              child: Text(
                player.name[0],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Age ${player.age} • OVR ${_calculateOverallRating(player).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            
            // Best Position
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(bestRole),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bestRole.abbreviation,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${(bestCompatibility * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  } 
 Widget _buildRolesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role Compatibility Overview
          _buildRoleCompatibilityCard(),
          const SizedBox(height: 16),
          
          // Individual Player Roles
          _buildPlayerRolesCard(),
        ],
      ),
    );
  }

  Widget _buildRoleCompatibilityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Compatibility Matrix',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Matrix Header
          Row(
            children: [
              const SizedBox(width: 100), // Space for player names
              ...PlayerRole.values.map((role) {
                return Expanded(
                  child: Center(
                    child: Text(
                      role.abbreviation,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(role),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          
          // Matrix Rows
          ...widget.players.take(8).map((player) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  // Player Name
                  SizedBox(
                    width: 100,
                    child: Text(
                      player.name.length > 12 
                        ? '${player.name.substring(0, 12)}...'
                        : player.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Compatibility Cells
                  ...PlayerRole.values.map((role) {
                    double compatibility = player.calculateRoleCompatibility(role);
                    Color cellColor = _getRoleCompatibilityColor(player, role);
                    
                    return Expanded(
                      child: Container(
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: cellColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: cellColor,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(compatibility * 100).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: cellColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          
          if (widget.players.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing top 8 players',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerRolesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Role Assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ...widget.players.map((player) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPlayerRoleItem(player),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlayerRoleItem(EnhancedPlayer player) {
    PlayerRole currentRole = player.primaryRole;
    PlayerRole bestRole = player.getBestRole();
    bool isInStartingLineup = _roleAssignments.values.contains(player);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: isInStartingLineup 
          ? Border.all(color: Colors.blue[400]!, width: 1)
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Player Info
              CircleAvatar(
                radius: 16,
                backgroundColor: _getRoleColor(currentRole),
                child: Text(
                  player.name[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'OVR ${_calculateOverallRating(player).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Current Role
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(currentRole),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentRole.abbreviation,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              if (isInStartingLineup) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'STARTER',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Role Compatibility Bars
          Row(
            children: PlayerRole.values.map((role) {
              double compatibility = player.calculateRoleCompatibility(role);
              Color roleColor = _getRoleColor(role);
              bool isBestRole = role == bestRole;
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: compatibility,
                          child: Container(
                            decoration: BoxDecoration(
                              color: roleColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.abbreviation,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: isBestRole ? FontWeight.bold : FontWeight.normal,
                          color: isBestRole ? roleColor : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          if (currentRole != bestRole) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange[400]?.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[400]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orange[400],
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Better suited for ${bestRole.displayName}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lineup Analysis Card
          _buildLineupAnalysisCard(),
          const SizedBox(height: 16),
          
          // Optimization Suggestions Card
          _buildOptimizationSuggestionsCard(),
          const SizedBox(height: 16),
          
          // Performance Prediction Card
          _buildPerformancePredictionCard(),
        ],
      ),
    );
  }

  Widget _buildLineupAnalysisCard() {
    double averageCompatibility = _calculateAverageCompatibility();
    List<String> strengths = _getLineupStrengths();
    List<String> weaknesses = _getLineupWeaknesses();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lineup Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Overall Rating
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Compatibility',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(averageCompatibility * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getCompatibilityRatingColor(averageCompatibility),
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: averageCompatibility,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCompatibilityRatingColor(averageCompatibility),
                ),
                strokeWidth: 6,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Strengths and Weaknesses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strengths',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...strengths.map((strength) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[400],
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                strength,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Areas to Improve',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...weaknesses.map((weakness) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.orange[400],
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                weakness,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationSuggestionsCard() {
    List<String> suggestions = _getOptimizationSuggestions();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.amber[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Optimization Suggestions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (suggestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.thumb_up,
                    size: 32,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lineup looks great!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No immediate optimizations needed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          else
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[400]?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber[400]!, width: 1),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              );
            }),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _optimizeLineup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[400],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Auto-Optimize Lineup',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePredictionCard() {
    Map<String, double> predictions = _calculatePerformancePredictions();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Prediction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ...predictions.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPredictionItem(entry.key, entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(String category, double rating) {
    Color ratingColor = _getPerformanceRatingColor(rating);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ratingColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (rating / 100.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: ratingColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods and dialogs
  void _showPlayerSelectionDialog(PlayerRole role) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Select ${role.displayName}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _availablePlayers.length,
              itemBuilder: (context, index) {
                EnhancedPlayer player = _availablePlayers[index];
                double compatibility = player.calculateRoleCompatibility(role);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleCompatibilityColor(player, role),
                    child: Text(
                      player.name[0],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Compatibility: ${(compatibility * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Text(
                    'OVR ${_calculateOverallRating(player).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _getRoleCompatibilityColor(player, role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _roleAssignments[role] = player;
                      _availablePlayers.remove(player);
                      player.assignPrimaryRole(role);
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _optimizeLineup() {
    setState(() {
      // Reset all assignments
      _availablePlayers.addAll(_roleAssignments.values.whereType<EnhancedPlayer>());
      _roleAssignments.clear();
      
      // Get optimal assignments using RoleManager
      List<EnhancedPlayer> topPlayers = _availablePlayers.take(5).toList();
      if (topPlayers.length == 5) {
        List<PlayerRole> optimalRoles = RoleManager.getOptimalLineup(topPlayers);
        
        for (int i = 0; i < 5; i++) {
          PlayerRole role = optimalRoles[i];
          EnhancedPlayer player = topPlayers[i];
          
          _roleAssignments[role] = player;
          player.assignPrimaryRole(role);
          _availablePlayers.remove(player);
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lineup optimized based on player compatibility'),
        backgroundColor: Colors.green[400],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveLineup() {
    if (_isLineupValid()) {
      // Update team's role assignments
      widget.team.roleAssignments = Map.from(_roleAssignments);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lineup saved successfully'),
          backgroundColor: Colors.green[400],
          duration: const Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLineupIssues().join(', ')),
          backgroundColor: Colors.red[400],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _isLineupValid() {
    return _roleAssignments.values.every((player) => player != null);
  }

  List<String> _getLineupIssues() {
    List<String> issues = [];
    
    for (PlayerRole role in PlayerRole.values) {
      if (_roleAssignments[role] == null) {
        issues.add('${role.displayName} position not filled');
      }
    }
    
    return issues;
  }

  double _calculateOverallRating(EnhancedPlayer player) {
    return (player.shooting + 
            player.rebounding + 
            player.passing + 
            player.ballHandling + 
            player.perimeterDefense + 
            player.postDefense + 
            player.insideShooting) / 7.0;
  }

  Color _getRoleColor(PlayerRole role) {
    switch (role) {
      case PlayerRole.pointGuard:
        return Colors.blue[400]!;
      case PlayerRole.shootingGuard:
        return Colors.orange[400]!;
      case PlayerRole.smallForward:
        return Colors.green[400]!;
      case PlayerRole.powerForward:
        return Colors.purple[400]!;
      case PlayerRole.center:
        return Colors.red[400]!;
    }
  }

  Color _getRoleCompatibilityColor(EnhancedPlayer player, PlayerRole role) {
    double compatibility = player.calculateRoleCompatibility(role);
    
    if (compatibility >= 0.9) return Colors.green[400]!;
    if (compatibility >= 0.8) return Colors.lightGreen[400]!;
    if (compatibility >= 0.7) return Colors.yellow[400]!;
    if (compatibility >= 0.6) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  String _getCompatibilityLabel(double compatibility) {
    if (compatibility >= 0.9) return 'Excellent';
    if (compatibility >= 0.8) return 'Good';
    if (compatibility >= 0.7) return 'Fair';
    if (compatibility >= 0.6) return 'Poor';
    return 'Terrible';
  }

  double _calculateAverageCompatibility() {
    if (_roleAssignments.isEmpty) return 0.0;
    
    double totalCompatibility = 0.0;
    int count = 0;
    
    for (var entry in _roleAssignments.entries) {
      if (entry.value != null) {
        totalCompatibility += entry.value!.calculateRoleCompatibility(entry.key);
        count++;
      }
    }
    
    return count > 0 ? totalCompatibility / count : 0.0;
  }

  Color _getCompatibilityRatingColor(double rating) {
    if (rating >= 0.9) return Colors.green[400]!;
    if (rating >= 0.8) return Colors.lightGreen[400]!;
    if (rating >= 0.7) return Colors.yellow[400]!;
    if (rating >= 0.6) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  List<String> _getLineupStrengths() {
    List<String> strengths = [];
    
    // Check for high compatibility players
    int excellentFits = 0;
    for (var entry in _roleAssignments.entries) {
      if (entry.value != null) {
        double compatibility = entry.value!.calculateRoleCompatibility(entry.key);
        if (compatibility >= 0.9) excellentFits++;
      }
    }
    
    if (excellentFits >= 3) {
      strengths.add('Strong role compatibility across lineup');
    }
    
    // Check for balanced skills
    if (_roleAssignments.isNotEmpty) {
      double avgShooting = _getAverageSkill('shooting');
      double avgDefense = _getAverageSkill('defense');
      
      if (avgShooting >= 75) {
        strengths.add('Strong offensive capabilities');
      }
      if (avgDefense >= 75) {
        strengths.add('Solid defensive foundation');
      }
    }
    
    return strengths;
  }

  List<String> _getLineupWeaknesses() {
    List<String> weaknesses = [];
    
    // Check for poor compatibility
    int poorFits = 0;
    for (var entry in _roleAssignments.entries) {
      if (entry.value != null) {
        double compatibility = entry.value!.calculateRoleCompatibility(entry.key);
        if (compatibility < 0.7) poorFits++;
      }
    }
    
    if (poorFits >= 2) {
      weaknesses.add('Multiple players out of position');
    }
    
    // Check for skill gaps
    if (_roleAssignments.isNotEmpty) {
      double avgShooting = _getAverageSkill('shooting');
      double avgDefense = _getAverageSkill('defense');
      
      if (avgShooting < 65) {
        weaknesses.add('Limited offensive firepower');
      }
      if (avgDefense < 65) {
        weaknesses.add('Defensive vulnerabilities');
      }
    }
    
    return weaknesses;
  }

  double _getAverageSkill(String skillCategory) {
    List<EnhancedPlayer> assignedPlayers = _roleAssignments.values
        .whereType<EnhancedPlayer>()
        .toList();
    
    if (assignedPlayers.isEmpty) return 0.0;
    
    double total = 0.0;
    for (EnhancedPlayer player in assignedPlayers) {
      switch (skillCategory) {
        case 'shooting':
          total += (player.shooting + player.insideShooting) / 2.0;
          break;
        case 'defense':
          total += (player.perimeterDefense + player.postDefense) / 2.0;
          break;
      }
    }
    
    return total / assignedPlayers.length;
  }

  List<String> _getOptimizationSuggestions() {
    List<String> suggestions = [];
    
    // Check each position for better alternatives
    for (var entry in _roleAssignments.entries) {
      PlayerRole role = entry.key;
      EnhancedPlayer? currentPlayer = entry.value;
      
      if (currentPlayer != null) {
        double currentCompatibility = currentPlayer.calculateRoleCompatibility(role);
        
        // Look for better alternatives in available players
        for (EnhancedPlayer availablePlayer in _availablePlayers) {
          double availableCompatibility = availablePlayer.calculateRoleCompatibility(role);
          
          if (availableCompatibility > currentCompatibility + 0.1) {
            suggestions.add(
              'Consider ${availablePlayer.name} for ${role.displayName} '
              '(${(availableCompatibility * 100).toStringAsFixed(0)}% vs '
              '${(currentCompatibility * 100).toStringAsFixed(0)}%)'
            );
            break; // Only suggest one alternative per position
          }
        }
      }
    }
    
    return suggestions.take(3).toList(); // Limit to 3 suggestions
  }

  Map<String, double> _calculatePerformancePredictions() {
    List<EnhancedPlayer> assignedPlayers = _roleAssignments.values
        .whereType<EnhancedPlayer>()
        .toList();
    
    if (assignedPlayers.isEmpty) {
      return {
        'Offensive Rating': 0.0,
        'Defensive Rating': 0.0,
        'Team Chemistry': 0.0,
        'Overall Performance': 0.0,
      };
    }
    
    double offensiveRating = _getAverageSkill('shooting');
    double defensiveRating = _getAverageSkill('defense');
    double teamChemistry = _calculateAverageCompatibility() * 100;
    double overallPerformance = (offensiveRating + defensiveRating + teamChemistry) / 3.0;
    
    return {
      'Offensive Rating': offensiveRating,
      'Defensive Rating': defensiveRating,
      'Team Chemistry': teamChemistry,
      'Overall Performance': overallPerformance,
    };
  }

  Color _getPerformanceRatingColor(double rating) {
    if (rating >= 85) return Colors.green[400]!;
    if (rating >= 75) return Colors.lightGreen[400]!;
    if (rating >= 65) return Colors.yellow[400]!;
    if (rating >= 55) return Colors.orange[400]!;
    return Colors.red[400]!;
  }
}