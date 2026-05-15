# Flutter Features Analysis - lib/features/

## Table of Contents
1. [auth/](#auth)
2. [comic/](#comic)
3. [download/](#download)
4. [reader/](#reader)
5. [settings/](#settings)

---

## auth/

### Screens
| Screen | File | Description |
|--------|------|-------------|
| LoginScreen | `presentation/login_screen.dart` | Login form with email/password validation |
| RegisterScreen | `presentation/register_screen.dart` | Registration form with name/email/password/confirm password |

### Widgets Used
- TextFormField (email, password, name inputs)
- Form with GlobalKey for validation
- FilledButton, TextButton
- Icon (visibility toggle, app logo)
- CircularProgressIndicator (loading state)

### Data Models
| Model | File | Fields |
|-------|------|--------|
| AuthUser | `domain/auth_state.dart` | id, name, email, avatar, birthday, level, gender |
| AuthState | `domain/auth_state.dart` | isLoggedIn, isLoading, token, user, error |

### API Calls (via ApiClient)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/login` | POST | Login with email/password |
| `/auth/register` | POST | Register new user |
| `/auth/logout` | POST | Logout user |

### Riverpod Providers
```dart
// Provider: authStateProvider
// Type: StateNotifierProvider<AuthNotifier, AuthState>
// Located in: data/auth_repository.dart

// AuthNotifier methods:
// - login({required String email, required String password}) -> Future<bool>
// - register({required String email, required String password, required String name, String? birthday}) -> Future<bool>
// - logout() -> Future<void>
// - restore() -> Future<void>
```

---

## comic/

### Screens
| Screen | File | Description |
|--------|------|-------------|
| ComicListScreen | `presentation/comic_list_screen.dart` | Paginated grid of comics with infinite scroll |
| ComicDetailScreen | `presentation/comic_detail_screen.dart` | Comic info, tags, action buttons, episode list |
| SearchScreen | `presentation/search_screen.dart` | Search with category filtering |
| CommentsScreen | `presentation/comments_screen.dart` | Comment list with reply functionality |
| LeaderboardScreen | `presentation/leaderboard_screen.dart` | Daily/Weekly/Monthly rankings |
| CategoriesScreen | `presentation/categories_screen.dart` | Category grid |
| CategoryComicsScreen | `presentation/categories_screen.dart` | Comics filtered by category |
| MyFollowsScreen | `presentation/my_follows_screen.dart` | User's followed comics |
| MyFavouritesScreen | `presentation/my_favourites_screen.dart` | User's favourite comics |

### Widgets Used
- GridView.builder (comic lists)
- ListView.builder (episode list, comments, leaderboard)
- ComicCard (shared widget for comic thumbnails)
- CachedNetworkImage
- SliverAppBar, CustomScrollView, SliverList, SliverToBoxAdapter
- Chip, FilterChip (tags, category filters)
- Card, InkWell
- CircleAvatar, ClipOval
- RefreshIndicator
- LinearProgressIndicator
- PopupMenuButton
- TextField, InputDecoration

### Data Models
| Model | File | Fields |
|-------|------|--------|
| Comic | `domain/comic_model.dart` | id, title, author, coverUrl, description, tags, totalViews, likeCount, episodeCount, updatedAt, isLiked, isFollowed, isFavorite |
| Episode | `domain/comic_model.dart` | id, title, order, publishedAt |
| ComicDetail | `domain/comic_model.dart` | comic, episodes (combined model) |
| Category | `presentation/categories_screen.dart` | id, title, cover |
| Comment | `domain/comment_model.dart` | id, userId, userName, userAvatar, content, likeCount, isLiked, createdAt, parentId, replyCount |

### API Calls (via ApiClient)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `GET /comics?page=N` | GET | Comic list |
| `GET /comics/{id}` | GET | Comic detail |
| `GET /comics/{id}/eps` | GET | Episode list |
| `GET /comics/{id}/eps/{id}/pages` | GET | Episode page images |
| `GET /comics/search?q=...&c=...` | GET | Search comics |
| `GET /comics/leaderboard?tt=d/w/m&ct=VC` | GET | Rankings |
| `GET /categories` | GET | Category list |
| `GET /category?ccat=id` | GET | Comics by category |
| `GET /my/favourites?s=da&page=N` | GET | User's favorites |
| `GET /my/follows?s=dd&page=N` | GET | User's follows |
| `POST /comics/{id}/favourite` | POST | Favorite a comic |
| `DELETE /comics/{id}/favourite` | DELETE | Unfavorite |
| `POST /comics/{id}/follow` | POST | Follow a comic |
| `DELETE /comics/{id}/follow` | DELETE | Unfollow |
| `POST /comics/{id}/like` | POST | Like a comic |
| `GET /comics/{id}/comments?page=N` | GET | Comic comments |
| `POST /comics/{id}/comments` | POST | Send comment |
| `POST /comments/{id}/like` | POST | Like comment |
| `GET /comments/{id}/childrens?page=N` | GET | Reply comments |
| `POST /comments/{id}` | POST | Send reply |

### Riverpod Providers
```dart
// comic_list_screen.dart
comicListProvider          // FutureProvider.family<List<Comic>, int>

// comic_detail_screen.dart  
comicDetailProvider        // FutureProvider.family<ComicDetail, String>

// search_screen.dart
searchQueryProvider        // StateProvider<String>
selectedCategoryProvider  // StateProvider<String?>
searchResultProvider       // FutureProvider<List<Comic>>

// comments_screen.dart
commentsProvider           // FutureProvider.family<List<Comment>, String>

// leaderboard_screen.dart
rankTypeProvider           // StateProvider<RankType> (enum: daily/weekly/monthly)
leaderboardProvider        // FutureProvider<List<Comic>>

// categories_screen.dart
categoriesProvider         // FutureProvider<List<Category>>
categoryComicsProvider    // FutureProvider.family<List<Comic>, String>

// my_follows_screen.dart
myFollowsProvider          // FutureProvider<List<Comic>>

// my_favourites_screen.dart
myFavouritesProvider       // FutureProvider<List<Comic>>

// data/comic_repository.dart
comicRepositoryProvider    // Provider<ComicRepository>
```

---

## download/

### Screens
| Screen | File | Description |
|--------|------|-------------|
| DownloadsScreen | `presentation/download_screen.dart` | Download task list with status/progress |

### Widgets Used
- ListView.builder
- ListTile
- LinearProgressIndicator
- Icon (status icons: hourglass_empty, downloading, check_circle, error)
- Text (empty state messaging)

### Data Models
| Model | File | Fields |
|-------|------|--------|
| DownloadTask | `presentation/download_screen.dart` | comicId, comicTitle, episodeId, episodeTitle, status, progress, localPath |
| DownloadStatus | `presentation/download_screen.dart` | enum: pending, downloading, completed, failed |

### API Calls
- None (download functionality appears stub/simplified - no actual download API calls in code)

### Riverpod Providers
```dart
// download_screen.dart
downloadListProvider  // StateProvider<List<DownloadTask>>
```

---

## reader/

### Screens
| Screen | File | Description |
|--------|------|-------------|
| ReaderScreen | `presentation/reader_screen.dart` | Full-screen comic reader with PhotoView gallery |

### Widgets Used
- PhotoViewGallery (from photo_view package)
- PhotoViewGalleryPageOptions
- CachedNetworkImage / CachedNetworkImageProvider
- GestureDetector (tap to toggle controls)
- AnimatedPositioned (slide-in controls)
- AppBar (transparent, overlaid)
- PageController
- Slider (page indicator)
- IconButton (navigation)
- Dialog/BottomSheet (episode picker)

### Data Models
- Uses `Episode` from comic module
- `episodePagesProvider` returns `List<String>` (image URLs)

### API Calls (via ApiClient)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `GET /comics/{comicId}/eps/{episodeId}/pages` | GET | Get page image URLs for an episode |

### Riverpod Providers
```dart
// reader_screen.dart
episodePagesProvider  // FutureProvider.family<List<String>, ({String comicId, String episodeId})>
```

---

## settings/

### Screens
| Screen | File | Description |
|--------|------|-------------|
| SettingsScreen | `presentation/settings_screen.dart` | App settings (server, proxy, theme, cache) |

### Widgets Used
- ListView (settings sections)
- ListTile
- Divider
- SectionHeader (custom _SectionHeader widget)
- AlertDialog
- SimpleDialog
- TextField
- RadioListTile
- SwitchListTile (if used)

### Data Models
| Model | File | Fields |
|-------|------|--------|
| SettingsState | `presentation/settings_screen.dart` | apiBaseUrl, proxyType, proxyHost, proxyPort, themeMode |
| ProxyConfig | `core/utils/proxy_selector.dart` | type, host, port |
| ProxyType | `core/utils/proxy_selector.dart` | enum: none, socks5, http |

### API Calls
- None directly (settings affect API client configuration)

### Riverpod Providers
```dart
// settings_screen.dart
settingsScreenProvider  // StateNotifierProvider<SettingsNotifier, SettingsState>

// SettingsNotifier methods:
// - load() -> Future<void>
// - setApiBaseUrl(String url) -> Future<void>
// - setProxy(ProxyType type, String? host, int port) -> Future<void>
// - setThemeMode(ThemeMode mode) -> Future<void>
// - clearCache() -> Future<void>

// core/storage/settings_storage.dart
settingsStorageProvider  // Provider<SettingsStorage>
```

---

## Shared Components (lib/shared/)

### Widgets
| Widget | File | Used In |
|--------|------|---------|
| ComicCard | `widgets/comic_card.dart` | ComicListScreen, SearchScreen, CategoriesScreen, MyFollowsScreen, MyFavouritesScreen |
| CachedImage | `widgets/cached_image.dart` | Multiple screens |
| LoadingIndicator | `widgets/loading_indicator.dart` | Multiple screens |

### Constants
| File | Description |
|------|-------------|
| `constants/api_constants.dart` | All API endpoint URLs |
| `constants/app_colors.dart` | App color palette |
| `constants/app_strings.dart` | Localized strings |

---

## Storage
| Storage | File | Description |
|---------|------|-------------|
| SecureStorage | `core/storage/secure_storage.dart` | Token storage |
| SettingsStorage | `core/storage/settings_storage.dart` | App settings persistence |
| Database | `core/db/database.dart` | SQLite via Drift (search history, etc.) |
