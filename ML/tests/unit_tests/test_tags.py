import unittest
from libs import tag

class TagTests(unittest.TestCase):
    def test_process_tag_item(self):
        no_real_file = tag._process_tag_item((64,64),3,'Spurious')
        self.failUnless(no_real_file == None)

# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()
