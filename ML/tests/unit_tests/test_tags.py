import unittest
import os, sys
from libs import tag
from libs import script

HERE = os.path.abspath(os.path.dirname(__file__))+'/'

class TagTests(unittest.TestCase):



    def test_collect_filenames(self):                             
        files = tag._collect_filenames_and_labels(HERE+'test_data/','*.jpg','.xml')
        self.assertEqual(len(files),25)


    def test_process_tag_item(self):
        no_real_file=tag._process_tag_item((64,64),3,'Spurious')
        self.failUnless(no_real_file == None)
        proc_file=tag._process_tag_item((64,64),3,HERE+'./test_data/11.jpg')
        self.failUnless(proc_file.shape[0] == 64*64*3)
    

    def test_whole_tagging(self):
        files = tag._collect_filenames_and_labels(HERE+'test_data/','*.jpg','.xml2')
        tagger = tag.Tagger(batch_size = 10,model=None,size=(10,10))
        tagger(files)
        found_xml = tag._collect_filenames_and_labels(HERE+'test_data/','*.xml2','.xml2')
        self.assertEqual(len(files),len(found_xml))
        for (xml,other) in found_xml:
            os.remove(xml)


# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()
