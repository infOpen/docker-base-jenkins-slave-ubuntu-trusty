require 'docker'
require 'infopen-docker'
require 'serverspec'

describe 'Dockerfile' do

    # Build Dockerfile
    before(:all) do
        @image = Docker::Image.build_from_dir('.')

        set :os, family: :debian
        set :backend, :docker
        set :docker_image, @image.id
    end

    # Once tests done, remove image
    after(:all) do
        Infopen::Docker::Lifecycle.remove_image_and_its_containers(@image)
    end


    # Tests
    #------

    it 'installs the right version of Ubuntu' do
        expect(get_os_version()).to include('Ubuntu 14.04')
    end

    it 'installs ssh server package' do
        expect(package('openssh-server')).to be_installed
    end

    it 'runs ssh server service' do
        expect(service('sshd')).to be_running
        expect(process('sshd')).to be_running
        expect(port(22)).to be_listening.with('tcp')
    end

    it 'install openjdk-7-jdk package' do
        expect(package('openjdk-7-jdk')).to be_installed
    end

    describe command('java -version') do
        its(:stderr) { should match( /java version "1.7/) }
        its(:exit_status) { should eql 0 }
    end

    describe user('jenkins') do
        it { should exist }
        it { should have_home_directory '/home/jenkins' }
        it { should belong_to_group 'jenkins' }
        its(:encrypted_password) { should match(/^\$6\$.{8}\$.{86}$/) }
    end

    # Functions
    #----------

    # Get os version of container
    def get_os_version
        command('lsb_release -a').stdout
    end
end

