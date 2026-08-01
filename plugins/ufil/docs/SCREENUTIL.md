# ScreenUtil Conventions

Use these rules in every presentation page and widget. They apply to modular
and single-module projects.

## Required mapping

| Intent | Required API |
| --- | --- |
| Vertical gap between widgets | `16.verticalSpace` |
| Horizontal gap between widgets | `16.horizontalSpace` |
| Horizontal size or inset | `.w` |
| Vertical size or inset | `.h` |
| Radius or square geometry | `.r` |
| Text and font-based icon size | `.sp` |

```dart
Padding(
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  child: const Content(),
),
16.verticalSpace,
Row(
  children: [
    const Leading(),
    8.horizontalSpace,
    const Label(),
  ],
),
Icon(Icons.home, size: 24.sp),
BorderRadius.circular(12.r),
```

## Spacing rule

Use `num.verticalSpace` and `num.horizontalSpace` for empty layout gaps.
Do not write `SizedBox(height: 16.h)` or `SizedBox(width: 16.w)` for spacing.

`SizedBox` remains valid when it constrains a child or supplies both
dimensions. Apply the correct ScreenUtil extension to each visual dimension:

```dart
SizedBox(
  width: 240.w,
  height: 160.h,
  child: const Preview(),
)
```

Never swap axes. A width cannot use `.h`, and a height cannot use `.w`.

## Exceptions

Zero, dimensionless values such as aspect ratios and line-height multipliers,
`double.infinity`, and durations do not use ScreenUtil. A requirement that
explicitly mandates device-independent logical pixels, such as an
accessibility floor, may remain unscaled only when the code documents why.

## Mandatory audit

Before reporting implementation or review complete, run:

```bash
"${UFIL_ROOT}/scripts/check-screenutil-spacing.sh" lib packages test
```

Fix every reported pure-spacing `SizedBox` and wrong-axis use. Then run the
normal formatter, analyzer, and tests.
