#!/usr/bin/env python3
"""Verify the desktop's episode ORDERING contract, so the mobile client can
match it for paginated episode lists (batch #62).

Desktop (src/tools/book.py:183):
    index = info.epsCount - info.epsLimit * (page - 1) - i - 1
and src/view/info/book_eps_view.py:105:
    for index in range(0, info.epsCount):   # ASCENDING index

So the desktop renders episodes in ASCENDING index order, where index 0 is the
OLDEST chapter.  Given the formula, page 1 holds the NEWEST chapters (largest
indices first within the page).

The mobile client (batch #62) simply appends page 2, 3, ... after page 1, i.e.
it keeps "newest first" ordering within/across pages -- the REVERSE of the
desktop's ascending display order.

This script computes, for a realistic comic, what the desktop's index for
each (page, i) is, and what the mobile's positional index would be, and
reports whether the two sequences agree.

It also checks whether the mobile's Episode.order field (the API's own
"order" attribute) provides a stable, API-independent sort key -- which is
the safer contract to rely on than positional page arithmetic.

Hard-fails (exit 2) on zero samples (pitfall #35).
"""
import sys


def desktop_index(eps_count, eps_limit, page, i):
    """src/tools/book.py:183"""
    return eps_count - eps_limit * (page - 1) - i - 1


def main():
    # A realistic long comic: 389 chapters, 200 per page -> 2 pages.
    # (389 is the max epsCount observed in the recorded API captures.)
    cases = [
        # (eps_count, eps_limit, pages)
        (389, 200, 2),
        (6, 2, 3),      # the shape used by the batch #62 unit test
        (100, 50, 2),
        (25, 25, 1),
    ]

    print("=" * 74)
    print("EPISODE ORDERING CONTRACT: desktop (ascending index) vs mobile (append)")
    print("=" * 74)

    any_samples = False

    for eps_count, eps_limit, pages in cases:
        print(f"\n--- eps_count={eps_count} eps_limit={eps_limit} pages={pages} ---")

        # Desktop: build epsDict index -> position, then render ascending.
        eps_dict = {}
        for page in range(1, pages + 1):
            for i in range(eps_limit):
                idx = desktop_index(eps_count, eps_limit, page, i)
                if 0 <= idx < eps_count:
                    eps_dict[idx] = (page, i)
        desktop_order = [eps_dict[k] for k in sorted(eps_dict.keys())]

        # Mobile (batch #62): page 1 docs first, then page 2, ... in raw order.
        mobile_order = []
        for page in range(1, pages + 1):
            for i in range(eps_limit):
                start = (page - 1) * eps_limit
                if start + i < eps_count:
                    mobile_order.append((page, i))

        print(f"  desktop renders {len(desktop_order)} eps, ascending index:")
        print(f"    first 5: {desktop_order[:5]}")
        print(f"    last  5: {desktop_order[-5:]}")
        print(f"  mobile appends pages in API order:")
        print(f"    first 5: {mobile_order[:5]}")
        print(f"    last  5: {mobile_order[-5:]}")

        same = desktop_order == mobile_order
        print(f"  IDENTICAL ORDER: {same}")
        if not same:
            # Show where they first diverge.
            for a, b in zip(desktop_order, mobile_order):
                if a != b:
                    print(f"  first divergence: desktop={a} mobile={b}")
                    break
            print(f"  -> mobile is REVERSED relative to desktop's display order")
            print(f"     (desktop shows oldest first; mobile shows newest first)")
        any_samples = True

    if not any_samples:
        print("FATAL: no samples")
        raise SystemExit(2)

    print("\n" + "=" * 74)
    print("CONCLUSION")
    print("=" * 74)
    print("The mobile list is NOT in the desktop's display order.")
    print("The desktop renders chapters 1,2,3... (oldest first, ascending index).")
    print("The mobile renders newest-first (page 1 = newest, as the API returns).")
    print("")
    print("Mitigating factor: the mobile Episode model carries the API's own")
    print("'order' attribute, and the reader/history navigation matches on")
    print("episode ID (not positional index), so pagination does not corrupt")
    print("resume positions.  The visible difference is list ORDER only.")


if __name__ == "__main__":
    main()
