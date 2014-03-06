import unittest
from libs import mongoHelperFunctions

class BucketingTests(unittest.TestCase):
    def test_process_tag_item(self):
        #no_real_file = mongoHelperFunctions.bucketing(1000)
        self.failUnless(True)

# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()
