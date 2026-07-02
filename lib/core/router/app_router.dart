import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

// Home
import '../../features/home/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

// Chat
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/multi_model_compare_screen.dart';

// Create
import '../../features/image_gen/presentation/screens/image_gen_screen.dart';
import '../../features/image_gen/presentation/screens/image_gallery_screen.dart';
import '../../features/video_gen/presentation/screens/video_gen_screen.dart';
import '../../features/music_gen/presentation/screens/music_gen_screen.dart';

// Tools
import '../../features/code_ai/presentation/screens/code_editor_screen.dart';
import '../../features/code_ai/presentation/screens/code_projects_screen.dart';
import '../../features/terminal/presentation/screens/terminal_screen.dart';
import '../../features/document_ai/presentation/screens/document_ai_screen.dart';
import '../../features/workspace/presentation/screens/workspace_screen.dart';

// AI
import '../../features/voice_ai/presentation/screens/voice_ai_screen.dart';
import '../../features/search_ai/presentation/screens/search_ai_screen.dart';
import '../../features/agent_ai/presentation/screens/agents_screen.dart';
import '../../features/agent_ai/presentation/screens/agent_builder_screen.dart';
import '../../features/agent_ai/presentation/screens/agent_run_screen.dart';
import '../../features/agent_ai/presentation/screens/workflow_builder_screen.dart';
import '../../data/models/agent_model.dart';

// Settings
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/api_keys_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/usage_stats_screen.dart';
import '../../features/settings/presentation/screens/mcp_servers_screen.dart';
import '../../features/settings/presentation/screens/local_models_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Main Shell ────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeScreen(navigationShell: navigationShell),
        branches: [
          // Branch 0: Chat
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.chatList,
              builder: (_, __) => const ChatListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const ChatScreen(conversationId: null),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      ChatScreen(conversationId: state.pathParameters['id']),
                ),
                GoRoute(
                  path: 'compare',
                  builder: (_, __) => const MultiModelCompareScreen(),
                ),
              ],
            ),
          ]),

          // Branch 1: Create
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.imageGen,
              builder: (_, __) => const ImageGenScreen(),
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (_, __) =>
                      const ImageGalleryScreen(mode: GalleryMode.history),
                ),
                GoRoute(
                  path: 'gallery',
                  builder: (_, __) =>
                      const ImageGalleryScreen(mode: GalleryMode.gallery),
                ),
              ],
            ),
          ]),

          // Branch 2: Tools
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.codeEditor,
              builder: (_, __) => const CodeEditorScreen(),
              routes: [
                GoRoute(
                  path: 'projects',
                  builder: (_, __) => const CodeProjectsScreen(),
                ),
              ],
            ),
          ]),

          // Branch 3: AI Agents
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.agents,
              builder: (_, __) => const AgentsScreen(),
              routes: [
                GoRoute(
                  path: 'builder',
                  builder: (_, __) => const AgentBuilderScreen(),
                ),
                GoRoute(
                  path: 'workflows',
                  builder: (_, __) => const WorkflowBuilderScreen(),
                ),
              ],
            ),
          ]),

          // Branch 4: Settings
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.settings,
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'api-keys',
                  builder: (_, __) => const ApiKeysScreen(),
                ),
                GoRoute(
                  path: 'appearance',
                  builder: (_, __) => const AppearanceScreen(),
                ),
                GoRoute(
                  path: 'usage',
                  builder: (_, __) => const UsageStatsScreen(),
                ),
                GoRoute(
                  path: 'mcp',
                  builder: (_, __) => const McpServersScreen(),
                ),
                GoRoute(
                  path: 'local-models',
                  builder: (_, __) => const LocalModelsScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ── Top-level (full-screen) routes ────────────────────────────────
      GoRoute(
        path: RouteNames.videoGen,
        builder: (_, __) => const VideoGenScreen(),
      ),
      GoRoute(
        path: RouteNames.musicGen,
        builder: (_, __) => const MusicGenScreen(),
      ),
      GoRoute(
        path: RouteNames.terminal,
        builder: (_, __) => const TerminalScreen(),
      ),
      GoRoute(
        path: RouteNames.documentAI,
        builder: (_, __) => const DocumentAIScreen(),
      ),
      GoRoute(
        path: RouteNames.voiceAI,
        builder: (_, __) => const VoiceAIScreen(),
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (_, __) => const SearchAIScreen(),
      ),
      GoRoute(
        path: RouteNames.workspace,
        builder: (_, __) => const WorkspaceScreen(),
      ),
      GoRoute(
        path: RouteNames.agentRun,
        builder: (_, state) {
          final agent = state.extra as AgentModel?;
          if (agent == null) return const AgentsScreen();
          return AgentRunScreen(agent: agent);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.chatList),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
