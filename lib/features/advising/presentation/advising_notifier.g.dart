// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advising_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdvisingNotifier)
final advisingProvider = AdvisingNotifierProvider._();

final class AdvisingNotifierProvider
    extends $NotifierProvider<AdvisingNotifier, AdvisingState> {
  AdvisingNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'advisingProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$advisingNotifierHash();

  @$internal
  @override
  AdvisingNotifier create() => AdvisingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdvisingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdvisingState>(value),
    );
  }
}

String _$advisingNotifierHash() => r'6e3361948662cfcb3c311e7ae6c8405592ca2f30';

abstract class _$AdvisingNotifier extends $Notifier<AdvisingState> {
  AdvisingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdvisingState, AdvisingState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AdvisingState, AdvisingState>,
        AdvisingState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
