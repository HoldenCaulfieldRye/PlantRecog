import unittest
import run_tests

class TagTests(unittest.TestCase):
    def test_fail(self):
        print 'Testing must fail'
        self.failUnless(False)

# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def run():
    import noccn.noccn.tag
    print 'In ccn_tag run about to run unittest.main()'
    unittest.main()

def main():
    run_tests.setup_testing_path()
    import noccn.noccn.tag
    unittest.main()

if __name__ == '__main__':
    main()
