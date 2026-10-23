"""Offline admission tests; these do not qualify a Docker image or run promotion."""
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import review_image as module

class OriginTests(unittest.TestCase):
    def setUp(self):
        self.expected = dict(run_id=100, artifact_id=200, source_sha='a'*40, image_id='sha256:'+'b'*64, archive_sha256='c'*64)
        self.workflow = dict(id=300, path=module.WORKFLOW)
        self.run = dict(id=100, workflow_id=300, path=module.WORKFLOW, head_sha='a'*40,
                        repository=dict(full_name=module.REPOSITORY), status='completed', conclusion='success',
                        event='push', head_branch='codex/container-review-fixture', run_attempt=2, html_url='https://github.com/example/run/100')
        self.artifact = dict(id=200, expired=False, size_in_bytes=50, digest='sha256:'+'d'*64,
                             name='reviewed-exact-source-image-100-2', workflow_run=dict(id=100, head_sha='a'*40))
        self.jobs = [dict(name='build-review', conclusion='success', status='completed')]
    def verify(self, run=None, artifact=None, jobs=None, workflow=None):
        return module.verify_origin(self.expected, workflow or self.workflow, run or self.run,
                                    artifact or self.artifact, self.jobs if jobs is None else jobs)
    def test_exact_successful_origin(self):
        self.assertEqual(self.verify()['status'], 'VERIFIED')
    def test_wrong_run_workflow_source_repository_or_status(self):
        for field, bad in [('id',101),('workflow_id',301),('path','.github/workflows/other.yml'),('head_sha','e'*40),
                           ('repository',dict(full_name='elsewhere/repo')),('status','in_progress'),('conclusion','failure'),
                           ('event','pull_request'),('head_branch','main')]:
            with self.subTest(field=field):
                run=copy.deepcopy(self.run);run[field]=bad
                with self.assertRaises(ValueError):self.verify(run=run)
    def test_wrong_registered_workflow(self):
        with self.assertRaises(ValueError):self.verify(workflow=dict(id=300,path='wrong.yml'))
    def test_incomplete_failed_duplicate_or_skipped_build(self):
        for jobs in [[], self.jobs+self.jobs, [dict(name='build-review',conclusion='skipped',status='completed')],
                     [dict(name='build-review',conclusion='failure',status='completed')]]:
            with self.subTest(jobs=jobs),self.assertRaises(ValueError):self.verify(jobs=jobs)
    def test_wrong_expired_empty_attempt_digest_or_membership(self):
        for field,bad in [('id',201),('expired',True),('size_in_bytes',0),('digest',None),
                          ('name','reviewed-exact-source-image-100-1'),('workflow_run',dict(id=101,head_sha='a'*40)),
                          ('workflow_run',dict(id=100,head_sha='e'*40))]:
            with self.subTest(field=field):
                item=copy.deepcopy(self.artifact);item[field]=bad
                with self.assertRaises((ValueError,TypeError)):self.verify(artifact=item)
    def test_input_validation_and_injection_rejection(self):
        values={'REVIEW_'+k.upper():str(v) for k,v in self.expected.items()}
        with patch.dict('os.environ',values):self.assertEqual(module.expected_from_environment(),self.expected)
        for key in values:
            bad=values.copy();bad[key]='1; echo untrusted'
            with self.subTest(key=key),patch.dict('os.environ',bad),self.assertRaises(ValueError):module.expected_from_environment()

class LocalTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.root=Path(self.temp.name)
        (self.root/'image.tar.gz').write_bytes(b'offline fixture, not a real Docker image')
        self.expected=dict(run_id=100,artifact_id=200,source_sha='a'*40,image_id='sha256:'+'b'*64,
                           archive_sha256=hashlib.sha256((self.root/'image.tar.gz').read_bytes()).hexdigest())
        self.origin=dict(expected=self.expected,run_attempt=2,review_helpers_sha256={'review_image.py':'d'*64,'test_review_image.py':'e'*64})
        self.receipt=dict(kind='scientifically-qualified-image-review',status='PASS',run_id=100,run_attempt=2,
                          source_sha='a'*40,image_id=self.expected['image_id'],archive_sha256=self.expected['archive_sha256'],
                          repository=module.REPOSITORY,production_sha256='f'*64,qualification_sha256='0'*64,
                          review_helpers_sha256=self.origin['review_helpers_sha256'],approval_input=False,
                          gates=['installed-package','native-HDF5-public-R-all-families','power-checkpoint','unchanged-resume','source-unchanged'])
        self.source=dict(git_head='a'*40,production_sha256='f'*64,qualification_sha256='0'*64,scientific_archive_sha256=module.ARCHIVE)
        self.image=dict(Id=self.expected['image_id'],Architecture='amd64',Os='linux',Config=dict(Labels={
            'org.opencontainers.image.source':'https://github.com/'+module.REPOSITORY,'org.opencontainers.image.revision':'a'*40}))
        self.write('review-receipt.json',self.receipt);self.write('source-before.json',self.source);self.write('source-after.json',self.source)
        self.write('context/source.json',dict(archive_sha256=module.ARCHIVE))
        self.write('scientific-parity/source-before.json',dict(source='same'));self.write('scientific-parity/source-after.json',dict(source='same'))
        self.write('host-engine.json',dict(nextflow_version='25.10.4',parser_override=None,java={'java.vendor':'Eclipse Adoptium','java.runtime.version':'17.0.10+7'}))
        self.write('image-inspect.json',[self.image]);self.write('loaded-inspect.json',[self.image])
        (self.root/'image-id').write_text(self.expected['image_id']+'\n')
        (self.root/'image.sha256').write_text(self.expected['archive_sha256']+'  image.tar.gz\n')
    def write(self,name,value):
        path=self.root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(value))
    def test_exact_archive_and_loaded_identity(self):
        self.assertEqual(module.verify_local(self.root,self.origin)['status'],'VERIFIED')
        self.assertTrue(module.verify_local(self.root,self.origin,True)['loaded_image_checked'])
    def test_corrupt_archive(self):
        (self.root/'image.tar.gz').write_bytes(b'corrupt')
        with self.assertRaises(ValueError):module.verify_local(self.root,self.origin)
    def test_unapproved_checksum_path(self):
        (self.root/'image.sha256').write_text(self.expected['archive_sha256']+'  ../elsewhere\n')
        with self.assertRaises(ValueError):module.verify_local(self.root,self.origin)
    def test_receipt_source_image_attempt_helper_and_gate_mutations(self):
        for key,bad in [('status','FAILED'),('run_id',101),('source_sha','e'*40),('image_id','sha256:'+'f'*64),
                        ('archive_sha256','c'*64),('run_attempt',1),('repository','other/repo'),('approval_input',True),
                        ('review_helpers_sha256',{}),('gates',['installed-package'])]:
            with self.subTest(key=key):
                altered=copy.deepcopy(self.receipt);altered[key]=bad;self.write('review-receipt.json',altered)
                with self.assertRaises(ValueError):module.verify_local(self.root,self.origin)
        self.write('review-receipt.json',self.receipt)
    def test_changed_source_or_wrong_package(self):
        for field,bad in [('git_head','e'*40),('scientific_archive_sha256','e'*64),('production_sha256','e'*64)]:
            with self.subTest(field=field):
                altered=dict(self.source);altered[field]=bad
                self.write('source-before.json',altered);self.write('source-after.json',altered)
                with self.assertRaises(ValueError):module.verify_local(self.root,self.origin)
    def test_wrong_loaded_id_platform_or_labels(self):
        for field,bad in [('Id','sha256:'+'e'*64),('Architecture','arm64'),('Os','other'),('Config',{'Labels':{}})]:
            with self.subTest(field=field):
                altered=copy.deepcopy(self.image);altered[field]=bad;self.write('loaded-inspect.json',[altered])
                with self.assertRaises((ValueError,KeyError)):module.verify_local(self.root,self.origin,True)
    def test_wrong_runtime_or_scientific_source(self):
        self.write('host-engine.json',dict(nextflow_version='26.10.3',parser_override=None,java={}))
        with self.assertRaises(ValueError):module.verify_local(self.root,self.origin)

if __name__ == '__main__':unittest.main()
