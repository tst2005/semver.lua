local v = require 'semver'

local function checkVersion(ver, major, minor, patch, prerelease, build)
  assert.equal(major, ver.major)
  assert.equal(minor, ver.minor)
  assert.equal(patch, ver.patch)
  assert.equal(prerelease, ver.prerelease)
  assert.equal(build, ver.build)
end

describe('semver', function()

  describe('creation', function()

    describe('from numbers', function()
      it('parses 3 numbers correctly', function()
        checkVersion(v(1,2,3), 1,2,3)
      end)

      it('parses 2 numbers correctly', function()
        checkVersion(v(1,2), 1,2,0)
      end)

      it('parses 1 number correctly', function()
        checkVersion(v(1), 1,0,0)
      end)

      it('parses prereleases', function()
        checkVersion(v(1,2,3,"alpha"), 1,2,3,"alpha")
      end)
      it('parses builds', function()
        checkVersion(v(1,2,3,nil,"build.1"), 1,2,3,nil,"build.1")
      end)
      it('parses prereleases + builds', function()
        checkVersion(v(1,2,3,"alpha","build.1"), 1,2,3,"alpha","build.1")
      end)
    end)

    describe("from strings", function()
      test("1.2.3", function()
        checkVersion( v'1.2.3', 1,2,3)
      end)
      test("10.20.123", function()
        checkVersion( v'10.20.123', 10,20,123)
      end)
      test("2.0", function()
        checkVersion( v'2.0', 2,0,0)
      end)
      test("5", function()
        checkVersion( v'5', 5,0,0)
      end)
      test("1.2.3-alpha", function()
        checkVersion( v'1.2.3-alpha', 1,2,3,'alpha' )
      end)
      test("1.2.3+build.15", function()
        checkVersion( v'1.2.3+build.15', 1,2,3,nil,'build.15' )
      end)
      test("1.2.3-rc1+build.15", function()
        checkVersion( v'1.2.3-rc1+build.15', 1,2,3,'rc1','build.15' )
      end)
    end)

    describe('errors', function()
      test('no parameters are passed', function()
        assert.error(function() v() end)
      end)
      test('negative numbers', function()
        assert.error(function() v(-1, 0, 0) end)
        assert.error(function() v( 0,-1, 0) end)
        assert.error(function() v( 0, 0,-1) end)
      end)
      test('floats', function()
        assert.error(function() v(.1, 0, 0) end)
        assert.error(function() v( 0,.1, 0) end)
        assert.error(function() v( 0, 0,.1) end)
      end)
      test('empty string', function()
        assert.error(function() v("") end)
      end)
      test('garbage at the beginning of the string', function()
        assert.error(function() v("foobar1.2.3") end)
      end)
      test('garbage at the end of the string', function()
        assert.error(function() v("1.2.3foobar") end)
      end)
      test('a non-string or number is passed', function()
        assert.error(function() v({}) end)
      end)
      test('an invalid prerelease', function()
        assert.error(function() v'1.2.3-%?' end)
      end)
      test('an invalid build', function()
        assert.error(function() v'1.2.3+%?' end)
      end)
    end)
  end)

  describe("tostring", function()
    it("works with major, minor and patch", function()
      assert.equal("1.2.3", tostring(v(1,2,3)))
    end)

    it("works with a prerelease", function()
      assert.equal("1.2.3-beta", tostring(v(1,2,3,'beta')))
    end)
    it("works with a build", function()
      assert.equal("1.2.3+foobar", tostring(v(1,2,3,nil,'foobar')))
    end)
    it("works with a prerelease and a build", function()
      assert.equal("1.2.3-alpha+foobar", tostring(v'1.2.3-alpha+foobar'))
    end)
  end)

  describe("==", function()
    it("is true when major, minor and patch are the same", function()
      assert.equal(v(1,2,3), v'1.2.3')
    end)
    it("is false when major, minor and patch are not the same", function()
      assert.not_equal(v(1,2,3), v(4,5,6))
    end)
    it("false if all is the same except the prerelease", function()
      assert.not_equal(v(1,2,3), v'1.2.3-alpha')
    end)
    it("false if all is the same except the build", function()
      assert.not_equal(v(1,2,3), v'1.2.3+peter.1')
    end)
  end)

  describe("<", function()
    test("true if major < minor", function()
      assert.is_true(v'1.100.10' < v'2.0.0')
    end)
    test("false if major > minor", function()
      assert.is_true(v'2' > v'1')
    end)
    test("true if major = major but minor < minor", function()
      assert.is_true(v'1.2.0' < v'1.3.0')
    end)
    test("false if minor < minor", function()
      assert.is_false(v'1.1' < v'1.0')
    end)
    test("true if major =, minor =, but patch <", function()
      assert.is_true(v'0.0.1' < v'0.0.10')
    end)
    test("false if major =, minor =, but patch >", function()
      assert.is_true(v'0.0.2' > v'0.0.1')
    end)
    describe("prereleases", function()
      test("false if exact same prerelease", function()
        assert.is_false(v'1.0.0-beta' < v'1.0.0-beta')
      end)
      test("#focus a prerelease version is less than the official version", function()
        assert.is_true(v'1.0.0-rc1' < v'1.0.0')
        assert.is_true(v'1.2.3' > v'1.2.3-alpha')
        assert.is_false(v'1.0.0-rc1' > v'1.0.0')
        assert.is_false(v'1.2.3' < v'1.2.3-alpha')
      end)
      test("identifiers with only digits are compared numerically", function()
        assert.is_true(v'1.0.0-1' < v'1.0.0-2')
        assert.is_false(v'1.0.0-1' > v'1.0.0-2')
      end)
      test("idendifiers with letters or dashes are compared lexiconumerically", function()
        assert.is_true(v'1.0.0-alpha' < v'1.0.0-beta')
        assert.is_true(v'1.0.0-alpha-10' < v'1.0.0-alpha-2')
        assert.is_false(v'1.0.0-alpha' > v'1.0.0-beta')
        assert.is_false(v'1.0.0-alpha-10' > v'1.0.0-alpha-2')
      end)
      test("numerical ids always have less priority than lexiconumericals", function()
        assert.is_true(v'1.0.0-1' < v'1.0.0-alpha')
        assert.is_true(v'1.0.0-2' < v'1.0.0-1asdf')
        assert.is_false(v'1.0.0-1' > v'1.0.0-alpha')
        assert.is_false(v'1.0.0-2' > v'1.0.0-1asdf')
      end)
      test("identifiers can be separated by colons; they must be compared individually", function()
        --assert.is_true(v'1.0.0-alpha'   < v'1.0.0-alpha.1')
        --assert.is_true(v'1.0.0-alpha.1' < v'1.0.0-beta.2')
        --assert.is_true(v'1.0.0-beta.2'  < v'1.0.0-beta.11')
        --assert.is_true(v'1.0.0-beta.11' < v'1.0.0-rc.1')
        assert.is_false(v'1.0.0-alpha'   > v'1.0.0-alpha.1')
        --assert.is_false(v'1.0.0-alpha.1' > v'1.0.0-beta.2')
        --assert.is_false(v'1.0.0-beta.2'  > v'1.0.0-beta.11')
        --assert.is_false(v'1.0.0-beta.11' > v'1.0.0-rc.1')
      end)
    end)
    describe("builds", function()
      test("false if exact same build", function()
        assert.is_false(v'1.0.0+build1' < v'1.0.0+build1')
      end)
      test("a regular (not-build) version is always less than a build version", function()
        assert.is_true(v'1.0.0' < v'1.0.0+12')
        assert.is_false(v'1.0.0' > v'1.0.0+12')
      end)
      test("identifiers with only digits are compared numerically", function()
        assert.is_true(v'1.0.0+1' < v'1.0.0+2')
        assert.is_true(v'1.0.0+2' < v'1.0.0+10')
        assert.is_false(v'1.0.0+1' > v'1.0.0+2')
        assert.is_false(v'1.0.0+2' > v'1.0.0+10')
      end)
      test("idendifiers with letters or dashes are compared lexiconumerically", function()
        assert.is_true(v'1.0.0+build1'  < v'1.0.0+build2')
        assert.is_true(v'1.0.0+build10' < v'1.0.0+build2')
        assert.is_false(v'1.0.0+build1'  > v'1.0.0+build2')
        assert.is_false(v'1.0.0+build10' > v'1.0.0+build2')
      end)
      test("numerical ids always have less priority than lexiconumericals", function()
        assert.is_true(v'1.0.0+1' < v'1.0.0+build1')
        assert.is_true(v'1.0.0+2' < v'1.0.0+1build')
        assert.is_false(v'1.0.0+1' > v'1.0.0+build1')
        assert.is_false(v'1.0.0+2' > v'1.0.0+1build')
      end)
      test("identifiers can be separated by colons; they must be compared individually", function()
        assert.is_true(v'1.0.0+0.3.7' < v'1.3.7+build')
        assert.is_true(v'1.3.7+build' < v'1.3.7+build.2.b8f12d7')
        assert.is_true(v'1.3.7+build.2.b8f12d7' < v'1.3.7+build.11.e0f985a')
        assert.is_false(v'1.0.0+0.3.7' > v'1.3.7+build')
        assert.is_false(v'1.3.7+build' > v'1.3.7+build.2.b8f12d7')
        assert.is_false(v'1.3.7+build.2.b8f12d7' > v'1.3.7+build.11.e0f985a')
      end)
    end)
    test("#focus prereleases + builds", function()
      --assert.is_true(v'1.0.0-rc.1' < v'1.0.0-rc.1+build.1')
      --assert.is_true(v'1.0.0-rc.1+build.1' < v'1.0.0')
      --assert.is_false(v'1.0.0-rc.1' > v'1.0.0-rc.1+build.1')
      assert.is_false(v'1.0.0-rc.1+build.1' > v'1.0.0')
    end)
  end)

  describe("nextPatch", function()
    it("increases the patch number by 1", function()
      assert.equal(v'1.0.1', v'1.0.0':nextPatch())
    end)
    it("resets prerelease and build", function()
      assert.equal(v'1.0.1', v'1.0.0-a+b':nextPatch())
    end)
  end)

  describe("nextMinor", function()
    it("increases the minor number by 1", function()
      assert.equal(v'1.2.0', v'1.1.0':nextMinor())
    end)
    it("resets the patch number, prerelease and build", function()
      assert.equal(v'1.2.0', v'1.1.7-a+b':nextMinor())
    end)
  end)

  describe("nextMajor", function()
    it("increases the major number by 1", function()
      assert.equal(v'2.0.0', v'1.0.0':nextMajor())
    end)
    it("resets the minor, patch, prerelease and build", function()
      assert.equal(v'2.0.0', v'1.2.3-a+b':nextMajor())
    end)
  end)


  -- This works like the "pessimisstic operator" in Rubygems.
  -- if a and b are versions, a ^ b means "b is backwards-compatible with a"
  -- in other words, "it's safe to upgrade from a to b"
  describe("^", function()
    test("true for self", function()
      assert.is_true(v(1,2,3) ^ v(1,2,3))
    end)
    test("different major versions mean it's always unsafe", function()
      assert.is_false(v(2,0,0) ^ v(3,0,0))
      assert.is_false(v(2,0,0) ^ v(1,0,0))
    end)

    test("patches, prereleases and builds are ignored", function()
      assert.is_true(v(1,2,3) ^ v(1,2,0))
      assert.is_true(v(1,2,3) ^ v(1,2,5))
      assert.is_true(v(1,2,3,'foo') ^ v(1,2,3))
      assert.is_true(v(1,2,3,nil,'bar') ^ v(1,2,3))
    end)

    test("it's safe to upgrade to a newer minor version", function()
      assert.is_true(v(1,2,0) ^ v(1,5,0))
    end)
    test("it's unsafe to downgrade to an earlier minor version", function()
      assert.is_false(v(1,5,0) ^ v(1,2,0))
    end)
  end)

  describe("_VERSION", function()
    it("can be extracted from the lib", function()
      local x = v._VERSION
      assert.equal('table', type(x))
    end)
  end)

end)
