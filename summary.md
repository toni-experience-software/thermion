# Summary

## What we tried
- Implemented a single change: moved the swapchain blit to the Vulkan platform `present` path and removed the Flutter-side `BlitFromSwapchain` call. The platform now waits on Filament's `finishedDrawing` semaphore before present, and the blit signals a separate semaphore for present.
- This change compiled and ran, but the output texture was pink (no rendered content).

## Observed results (from logs)
- Vulkan + D3D initialization succeeded (device creation, adapter match, texture creation, vkImage import).
- Flutter registered and unregistered textures repeatedly due to size changes.
- Flutter app reported platform-channel threading warnings (audioplayers) and a Riverpod assertion failure; these appear unrelated to Vulkan blit timing.

## Known-certain learnings
- The build is successful with the blit moved into the platform `present` hook.
- The runtime still produces a pink texture even though Vulkan and D3D resources are created successfully.
- The logs show repeated texture recreation as the surface size changes, so texture lifetimes are exercised.

## Hypotheses (not confirmed)
- The swapchain image layout assumptions in the blit barriers may still be wrong for this Filament path, causing the blit to copy invalid data (pink).
- The blit may be running before the swapchain image contains rendered content due to missing or incorrect semaphore use on this path.
- The pink output could indicate an sRGB/format mismatch or a D3D texture not being updated in time for Flutter to sample.
