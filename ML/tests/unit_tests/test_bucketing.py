import unittest
from libs import mongoHelperFunctions

class BucketingTests(unittest.TestCase):
    def test_invalid_component_tag(self):
        return_val = mongoHelperFunctions.bucketing(1000,'Rando',0.5)
        self.assertEqual(return_val, -1)
    def test_bucketing_threshold_zero(self):
        return_val = mongoHelperFunctions.get_buckets(0,None,0.0)
        self.assertEqual(len(return_val), 654)
    def test_exclude_synset(self):
        return_val = mongoHelperFunctions.exclude_synset('plant, flora, plant life')
        self.assertEqual(return_val, 'n00017222')
    def test_bucketing_script_failure(self):
        return_val = mongoHelperFunctions.bucketing(1000,'Leaf',0.5)
        self.assertNotEqual(return_val,-2)


# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()

# should test: "test_bucketing_threshold_zero" fail, update the assert 
# equal to be the result of the following function call (in python)
#
#        len(mongoHelperFunctions.get_buckets(0,None,0.0))
