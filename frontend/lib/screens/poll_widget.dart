import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PollWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final List<int> initialVotes;
  final int userVotedIndex;
  final ValueChanged<int>? onVote;

  const PollWidget({
    super.key,
    required this.question,
    required this.options,
    required this.initialVotes,
    this.userVotedIndex = -1,
    this.onVote,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  late int _votedIndex;
  late List<int> _votes;

  @override
  void initState() {
    super.initState();
    _votedIndex = widget.userVotedIndex;
    _votes = List.from(widget.initialVotes);
  }

  @override
  void didUpdateWidget(covariant PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userVotedIndex != oldWidget.userVotedIndex ||
        widget.initialVotes != oldWidget.initialVotes) {
      setState(() {
        _votedIndex = widget.userVotedIndex;
        _votes = List.from(widget.initialVotes);
      });
    }
  }

  int get totalVotes {
    return _votes.fold(0, (sum, item) => sum + item);
  }

  void _handleVote(int index) {
    if (_votedIndex != -1) return; // Can only vote once
    setState(() {
      _votedIndex = index;
      _votes[index] = _votes[index] + 1;
    });
    if (widget.onVote != null) {
      widget.onVote!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVoted = _votedIndex != -1;
    final int votesCount = _votes.fold(0, (sum, item) => sum + item);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            widget.question,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // Options
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final optionText = widget.options[index];
              final optionVotes = _votes[index];
              final percentage = totalVotes == 0 ? 0.0 : (optionVotes / totalVotes) * 100;
              final isUserVote = _votedIndex == index;

              final maxVotes = _votes.reduce((curr, next) => curr > next ? curr : next);
              final hasVotes = _votes.any((v) => v > 0);
              final isWinner = hasVotes && optionVotes == maxVotes;

              return GestureDetector(
                onTap: () => _handleVote(index),
                child: isVoted
                    ? _buildVotedOption(optionText, percentage, isUserVote, isWinner)
                    : _buildUnvotedOption(optionText, index),
              );
            },
          ),
          const SizedBox(height: 10),

          // Footer info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$votesCount votes',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              if (isVoted)
                Text(
                  'Voted',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF00FF7F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnvotedOption(String optionText, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[600]!, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              optionText,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[200],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotedOption(String optionText, double percentage, bool isUserVote, bool isWinner) {
    final highlightColor = isWinner ? const Color(0xFF00FF7F) : Colors.grey[400]!;
    final progressColor = isWinner 
        ? const Color(0xFF00FF7F).withValues(alpha: 0.25) 
        : Colors.grey[800]!.withValues(alpha: 0.25);
    final borderColor = isWinner 
        ? const Color(0xFF00FF7F).withValues(alpha: 0.4) 
        : Colors.grey[850]!;

    return Container(
      height: 46,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Stack(
        children: [
          // Animated Background progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage / 100),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  );
                },
              );
            },
          ),
          // Option Content text & %
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isUserVote) ...[
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00FF7F),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          optionText,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isWinner ? Colors.white : Colors.grey[300],
                            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: highlightColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
