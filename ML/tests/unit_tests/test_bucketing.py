import unittest
from libs import mongoHelperFunctions

class BucketingTests(unittest.TestCase):
    def test_invalid_component_tag(self):
        return_val = mongoHelperFunctions.bucketing(1000,'Rando',0.5)
        self.assertEqual(return_val, -1)

'''    def test_valid_component_tag(self):
        return_val = mongoHelperFunctions.bucketing(1000,'Leaf',0.5)
        self.failUnless(return_val is not None)
'''

'''    def test_bucketing_script_failure(self):
        return_val = mongoHelperFunctions.bucketing(1000,'Leaf',0.5)
        self.failUnless(return_val == -2)
'''


# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()
