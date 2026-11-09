import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../admin_auth/viewmodels/admin_auth_view_model.dart';
import '../models/admin_space.dart';
import '../viewmodels/admin_space_list_view_model.dart';

class AdminSpaceListPage extends StatefulWidget {
  const AdminSpaceListPage({
    super.key,
    required this.onCreate,
    required this.onOpenSpace,
    required this.onLogout,
  });

  final VoidCallback onCreate;
  final ValueChanged<String> onOpenSpace;
  final VoidCallback onLogout;

  @override
  State<AdminSpaceListPage> createState() => _AdminSpaceListPageState();
}

class _AdminSpaceListPageState extends State<AdminSpaceListPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminSpaceListViewModel>().load();
    });
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSpaceListViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.load,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _buildHeader(),

              const SizedBox(height: 16),

              _buildSummary(viewModel),

              const SizedBox(height: 24),

              _buildSearchField(viewModel),

              const SizedBox(height: 16),

              _buildFilters(viewModel),

              const SizedBox(height: 12),

              if (viewModel.isLoading && viewModel.spaces.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (viewModel.errorMessage != null &&
                  viewModel.spaces.isEmpty)
                _buildError(viewModel)
              else if (viewModel.visibleSpaces.isEmpty)
                _buildEmptyState()
              else
                ...viewModel.visibleSpaces.map(
                  (space) => _buildSpaceRow(space),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(child: Text('공간 관리', style: AppTypography.h1)),

        IconButton(
          tooltip: '관리자 계정',
          onPressed: _showAccountMenu,
          icon: const Icon(
            Icons.account_circle_outlined,
            color: AppColors.gray700,
            size: 25,
          ),
        ),

        const SizedBox(width: 4),

        ElevatedButton.icon(
          onPressed: widget.onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('등록'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.label.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(AdminSpaceListViewModel viewModel) {
    final normalStyle = AppTypography.body2;

    return Text.rich(
      TextSpan(
        style: normalStyle,
        children: [
          TextSpan(
            text: '전체 ${viewModel.totalCount}',
            style: normalStyle.copyWith(
              color: AppColors.gray900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: '  ·  '),
          TextSpan(
            text: '비공개 ${viewModel.privateCount}',
            style: normalStyle.copyWith(color: AppColors.gray600),
          ),
          const TextSpan(text: '  ·  '),
          TextSpan(
            text: '재조사 요청 ${viewModel.reinspectionSpaceCount}',
            style: normalStyle.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AdminSpaceListViewModel viewModel) {
    final isFocused = _searchFocusNode.hasFocus;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.primary : AppColors.gray200,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.gray500, size: 21),
          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: viewModel.setSearchQuery,
              style: AppTypography.body1,
              decoration: InputDecoration(
                hintText: '공간·건물 이름 입력',
                hintStyle: AppTypography.body1.copyWith(
                  color: AppColors.gray400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                viewModel.setSearchQuery('');
              },
              icon: const Icon(Icons.close, size: 18, color: AppColors.gray500),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(AdminSpaceListViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: '전체',
            filter: AdminSpaceFilter.all,
            selected: viewModel.filter,
            viewModel: viewModel,
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '비공개',
            filter: AdminSpaceFilter.privateOnly,
            selected: viewModel.filter,
            viewModel: viewModel,
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '재조사 요청',
            filter: AdminSpaceFilter.reinspection,
            selected: viewModel.filter,
            viewModel: viewModel,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required AdminSpaceFilter filter,
    required AdminSpaceFilter selected,
    required AdminSpaceListViewModel viewModel,
  }) {
    final isSelected = filter == selected;

    return InkWell(
      onTap: () => viewModel.setFilter(filter),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray900 : AppColors.gray100,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: isSelected ? AppColors.white : AppColors.gray700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSpaceRow(AdminSpace space) {
    return InkWell(
      onTap: () => widget.onOpenSpace(space.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.gray200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3,
                  ),

                  const SizedBox(height: 5),

                  Text(
                    space.location,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '최근 수정 ${_formatDate(space.updatedAt)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (space.hasReinspectionRequest) ...[
                  _StatusBadge(
                    label: '요청 ${space.reinspectionRequestCount}',
                    background: AppColors.primaryTint,
                    foreground: AppColors.primary,
                  ),
                  const SizedBox(height: 6),
                ],

                _StatusBadge(
                  label: space.isPublic ? '공개' : '비공개',
                  background: space.isPublic
                      ? AppColors.positiveTint
                      : AppColors.gray100,
                  foreground: space.isPublic
                      ? AppColors.positive
                      : AppColors.gray600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 40, color: AppColors.gray400),
          const SizedBox(height: 12),
          Text('검색 결과가 없어요.', style: AppTypography.h3),
          const SizedBox(height: 6),
          Text('검색어 또는 필터를 변경해 보세요.', style: AppTypography.body2),
        ],
      ),
    );
  }

  Widget _buildError(AdminSpaceListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(viewModel.errorMessage!, style: AppTypography.body1),
          const SizedBox(height: 12),
          TextButton(onPressed: viewModel.load, child: const Text('다시 시도')),
        ],
      ),
    );
  }

  void _showAccountMenu() {
    final admin = context.read<AdminAuthViewModel>().admin;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(admin?.name ?? '관리자 계정', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(admin?.email ?? '', style: AppTypography.body2),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    widget.onLogout();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.gray900,
                    backgroundColor: AppColors.gray100,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '로그아웃',
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}.$month.$day';
}
