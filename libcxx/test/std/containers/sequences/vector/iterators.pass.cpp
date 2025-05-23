//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// <vector>

// iterator       begin();
// iterator       end();
// const_iterator begin()  const;
// const_iterator end()    const;
// const_iterator cbegin() const;
// const_iterator cend()   const;

#include <vector>
#include <cassert>
#include <iterator>

#include "test_macros.h"
#include "min_allocator.h"

struct A {
  int first;
  int second;
};

TEST_CONSTEXPR_CXX20 bool tests() {
  {
    typedef int T;
    typedef std::vector<T> C;
    C c;
    C::iterator i = c.begin();
    C::iterator j = c.end();
    assert(std::distance(i, j) == 0);
    assert(i == j);
  }
  {
    typedef int T;
    typedef std::vector<T> C;
    const C c;
    C::const_iterator i = c.begin();
    C::const_iterator j = c.end();
    assert(std::distance(i, j) == 0);
    assert(i == j);
  }
  {
    typedef int T;
    typedef std::vector<T> C;
    C c;
    C::const_iterator i = c.cbegin();
    C::const_iterator j = c.cend();
    assert(std::distance(i, j) == 0);
    assert(i == j);
    assert(i == c.end());
  }
  {
    typedef int T;
    typedef std::vector<T> C;
    const T t[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    C c(std::begin(t), std::end(t));
    C::iterator i = c.begin();
    assert(*i == 0);
    ++i;
    assert(*i == 1);
    *i = 10;
    assert(*i == 10);
    assert(std::distance(c.begin(), c.end()) == 10);
  }
  {
    typedef int T;
    typedef std::vector<T> C;
    C::iterator i;
    C::const_iterator j;
    (void)i;
    (void)j;
  }
#if TEST_STD_VER >= 11
  {
    typedef int T;
    typedef std::vector<T, min_allocator<T>> C;
    C c;
    C::iterator i = c.begin();
    C::iterator j = c.end();
    assert(std::distance(i, j) == 0);

    assert(i == j);
    assert(!(i != j));

    assert(!(i < j));
    assert((i <= j));

    assert(!(i > j));
    assert((i >= j));

#  if TEST_STD_VER >= 20
    // P1614 + LWG3352
    // When the allocator does not have operator<=> then the iterator uses a
    // fallback to provide operator<=>.
    // Make sure to test with an allocator that does not have operator<=>.
    static_assert(!std::three_way_comparable<min_allocator<int>, std::strong_ordering>);
    static_assert(std::three_way_comparable<typename C::iterator, std::strong_ordering>);

    std::same_as<std::strong_ordering> decltype(auto) r1 = i <=> j;
    assert(r1 == std::strong_ordering::equal);
#  endif
  }
  {
    typedef int T;
    typedef std::vector<T, min_allocator<T>> C;
    const C c;
    C::const_iterator i = c.begin();
    C::const_iterator j = c.end();
    assert(std::distance(i, j) == 0);

    assert(i == j);
    assert(!(i != j));

    assert(!(i < j));
    assert((i <= j));

    assert(!(i > j));
    assert((i >= j));

#  if TEST_STD_VER >= 20
    // When the allocator does not have operator<=> then the iterator uses a
    // fallback to provide operator<=>.
    // Make sure to test with an allocator that does not have operator<=>.
    static_assert(!std::three_way_comparable<min_allocator<int>, std::strong_ordering>);
    static_assert(std::three_way_comparable<typename C::iterator, std::strong_ordering>);

    std::same_as<std::strong_ordering> decltype(auto) r1 = i <=> j;
    assert(r1 == std::strong_ordering::equal);
#  endif
  }
  {
    typedef int T;
    typedef std::vector<T, min_allocator<T>> C;
    C c;
    C::const_iterator i = c.cbegin();
    C::const_iterator j = c.cend();
    assert(std::distance(i, j) == 0);
    assert(i == j);
    assert(i == c.end());
  }
  {
    typedef int T;
    typedef std::vector<T, min_allocator<T>> C;
    const T t[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    C c(std::begin(t), std::end(t));
    C::iterator i = c.begin();
    assert(*i == 0);
    ++i;
    assert(*i == 1);
    *i = 10;
    assert(*i == 10);
    assert(std::distance(c.begin(), c.end()) == 10);
  }
  {
    typedef int T;
    typedef std::vector<T, min_allocator<T>> C;
    C::iterator i;
    C::const_iterator j;
    (void)i;
    (void)j;
  }
  {
    typedef A T;
    typedef std::vector<T, min_allocator<T>> C;
    C c                 = {A{1, 2}};
    C::iterator i       = c.begin();
    i->first            = 3;
    C::const_iterator j = i;
    assert(j->first == 3);
  }
#endif
#if TEST_STD_VER > 11
  { // N3644 testing
    typedef std::vector<int> C;
    C::iterator ii1{}, ii2{};
    C::iterator ii4 = ii1;
    C::const_iterator cii{};
    assert(ii1 == ii2);
    assert(ii1 == ii4);

    assert(!(ii1 != ii2));

    assert((ii1 == cii));
    assert((cii == ii1));
    assert(!(ii1 != cii));
    assert(!(cii != ii1));
    assert(!(ii1 < cii));
    assert(!(cii < ii1));
    assert((ii1 <= cii));
    assert((cii <= ii1));
    assert(!(ii1 > cii));
    assert(!(cii > ii1));
    assert((ii1 >= cii));
    assert((cii >= ii1));
    assert(cii - ii1 == 0);
    assert(ii1 - cii == 0);
#  if TEST_STD_VER >= 20
    // P1614 + LWG3352
    std::same_as<std::strong_ordering> decltype(auto) r1 = ii1 <=> ii2;
    assert(r1 == std::strong_ordering::equal);

    std::same_as<std::strong_ordering> decltype(auto) r2 = cii <=> ii2;
    assert(r2 == std::strong_ordering::equal);
#  endif // TEST_STD_VER > 20
  }
#endif // TEST_STD_VER > 11

  return true;
}

int main(int, char**) {
  tests();
#if TEST_STD_VER > 17
  static_assert(tests());
#endif
  return 0;
}
