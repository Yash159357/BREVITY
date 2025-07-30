import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'dart:ui';
import 'package:brevity/controller/bloc/chat_bloc/chat_bloc.dart';
import 'package:brevity/controller/services/gemini_service.dart';
import 'package:brevity/controller/cubit/theme/theme_cubit.dart';
import 'package:brevity/models/article_model.dart';

class ChatScreen extends StatefulWidget {
  final Article article;
  const ChatScreen({super.key, required this.article});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController, _slideController, _pulseController;
  late Animation<double> _fadeAnimation, _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isComposing = false;
  String _pendingMessage = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    _slideController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _pulseController = AnimationController(vsync: this, duration: Duration(milliseconds: 2000))..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeCubit>().currentTheme;

    return BlocProvider(
      create: (context) => ChatBloc(geminiService: GeminiFlashService())..add(InitializeChat(article: widget.article)),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      theme.primaryColor.withValues(alpha:0.1),
                      Colors.black,
                      theme.primaryColor.withValues(alpha:0.05),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Gap(100),
                  Expanded(
                    child: _buildMessageList(theme),
                  ),
                  _buildGlassInputField(theme),
                ],
              ),
            ),
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: _buildGlassAppBar(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassAppBar(theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha:0.1), Colors.white.withValues(alpha:0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha:0.2)),
              ),
              child: Row(
                children: [
                  _buildGlassButton(Icons.arrow_back_ios_new, theme.primaryColor, () => Navigator.pop(context)),
                  Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.white, theme.primaryColor],
                          ).createShader(bounds),
                          child: Text('NewsAI Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        Text('Powered by Gemini', style: TextStyle(color: theme.primaryColor.withValues(alpha:0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      return _buildGlassButton(
                        Icons.delete_outline,
                        Colors.red,
                            () {
                          context.read<ChatBloc>().add(ClearChat());
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha:0.2), color.withValues(alpha:0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingArticleCard(theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha:0.15),
                  theme.primaryColor.withValues(alpha:0.05),
                  Colors.white.withValues(alpha:0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.primaryColor.withValues(alpha:0.3)),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha:0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [theme.primaryColor.withValues(alpha:0.4), theme.primaryColor.withValues(alpha:0.2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryColor.withValues(alpha:0.5)),
                  ),
                  child: Icon(Icons.auto_awesome, color: theme.primaryColor, size: 28),
                ),
                Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Article Context', style: TextStyle(color: theme.primaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      Gap(6),
                      Text(
                        widget.article.title,
                        style: TextStyle(color: Colors.white.withValues(alpha:0.95), fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(theme) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded || state is MessageSending) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is ChatLoaded) {
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: state.chatWindow.conversations.length + 1,
            physics: ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _buildFloatingArticleCard(theme),
                );
              }
              final conversation = state.chatWindow.conversations[index - 1];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + ((index - 1) * 100)),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: value,
                      child: Column(
                        children: [
                          _buildUserMessage(conversation.request, theme),
                          Gap(16),
                          _buildAiMessage(conversation.response, theme, shouldAnimate: index - 1 == state.chatWindow.conversations.length - 1),
                          Gap(24),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else if (state is MessageSending) {
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: state.chatWindow.conversations.length + 2,
            physics: ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _buildFloatingArticleCard(theme),
                );
              } else if (index < state.chatWindow.conversations.length + 1) {
                final conversation = state.chatWindow.conversations[index - 1];
                return Column(
                  children: [
                    _buildUserMessage(conversation.request, theme),
                    Gap(16),
                    _buildAiMessage(conversation.response, theme, shouldAnimate: false),
                    Gap(24),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildUserMessage(_pendingMessage, theme),
                    Gap(16),
                    _buildTypingIndicator(theme),
                  ],
                );
              }
            },
          );
        } else if (state is ChatError) {
          return ListView(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            physics: ClampingScrollPhysics(),
            children: [
              _buildFloatingArticleCard(theme),
              Gap(24),
              Center(
                child: Container(
                  padding: EdgeInsets.all(32),
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.withValues(alpha:0.15), Colors.red.withValues(alpha:0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(colors: [Colors.red.withValues(alpha:0.3), Colors.red.withValues(alpha:0.1)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.error_outline, color: Colors.red, size: 48),
                      ),
                      Gap(20),
                      Text('Something went wrong', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600)),
                      Gap(8),
                      Text(state.message, style: TextStyle(color: Colors.red.shade300, fontSize: 14), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return ListView(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          physics: ClampingScrollPhysics(),
          children: [
            _buildFloatingArticleCard(theme),
            Gap(24),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [theme.primaryColor.withValues(alpha:0.2), theme.primaryColor.withValues(alpha:0.05)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3),
                  ),
                  Gap(20),
                  Text('Initializing chat...', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserMessage(String message, theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(
              opacity: value,
              child: Align(
                alignment: Alignment.centerRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(6),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha:0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha:0.4),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        message,
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiMessage(String message, theme, {bool shouldAnimate = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-30 * (1 - value), 0),
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(
              opacity: value,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withValues(alpha:0.1), Colors.white.withValues(alpha:0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(24),
                        ),
                        border: Border.all(color: theme.primaryColor.withValues(alpha:0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.3),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [theme.primaryColor.withValues(alpha:0.4), theme.primaryColor.withValues(alpha:0.2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.primaryColor.withValues(alpha:0.5)),
                            ),
                            child: Icon(Icons.smart_toy, color: theme.primaryColor, size: 18),
                          ),
                          Gap(16),
                          Expanded(
                            child: shouldAnimate
                                ? TypewriterText(
                              text: message.trimRight(), // Trim trailing whitespace/newlines
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400, height: 1.4),
                            )
                                : Text(
                              message.trimRight(), // Trim trailing whitespace/newlines
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha:0.1), Colors.white.withValues(alpha:0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.primaryColor.withValues(alpha:0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha:0.2),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [theme.primaryColor.withValues(alpha:0.4), theme.primaryColor.withValues(alpha:0.2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.smart_toy, color: theme.primaryColor, size: 18),
                        ),
                        Gap(16),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                              ),
                            );
                          },
                        ),
                        Gap(16),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [theme.primaryColor, Colors.white],
                          ).createShader(bounds),
                          child: Text('Thinking...', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassInputField(theme) {
    return Container(
      margin: EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha:0.1), Colors.white.withValues(alpha:0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha:0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha:0.15), Colors.white.withValues(alpha:0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isComposing ? theme.primaryColor.withValues(alpha:0.6) : Colors.white.withValues(alpha:0.2),
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: Colors.white, fontSize: 15),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (text) => setState(() => _isComposing = text.isNotEmpty),
                          decoration: InputDecoration(
                            hintText: 'Ask me anything about this article...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.6)),
                            prefixIcon: Icon(Icons.auto_awesome_outlined, color: theme.primaryColor.withValues(alpha:0.8), size: 22),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Gap(16),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    final isLoading = state is MessageSending;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: _isComposing && !isLoading
                            ? LinearGradient(
                          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha:0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : LinearGradient(
                          colors: [Colors.grey.withValues(alpha:0.3), Colors.grey.withValues(alpha:0.1)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isComposing ? theme.primaryColor.withValues(alpha:0.6) : Colors.white.withValues(alpha:0.2),
                          width: 2,
                        ),
                        boxShadow: _isComposing && !isLoading
                            ? [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha:0.4),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: IconButton(
                            icon: isLoading
                                ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Icon(Icons.send_rounded, color: Colors.white, size: 24),
                            onPressed: _isComposing && !isLoading
                                ? () {
                              final message = _controller.text.trim();
                              if (message.isNotEmpty) {
                                final currentState = context.read<ChatBloc>().state;
                                if (currentState is ChatLoaded) {
                                  _pendingMessage = message;
                                  context.read<ChatBloc>().add(SendMessage(message: message, chatWindow: currentState.chatWindow));
                                }
                                _controller.clear();
                                setState(() => _isComposing = false);
                              }
                            }
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const TypewriterText({Key? key, required this.text, required this.style, this.duration = const Duration(milliseconds: 50)}) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * widget.duration.inMilliseconds),
      vsync: this,
    );
    _charAnimation = IntTween(begin: 0, end: widget.text.length).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charAnimation,
      builder: (context, child) {
        return Text(widget.text.substring(0, _charAnimation.value), style: widget.style);
      },
    );
  }
}