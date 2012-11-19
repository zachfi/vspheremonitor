require 'rubygems'
require 'rbvmomi'
require 'pp'
require 'alchemist'
require 'yaml'

class VSphereMonitoring

  def initialize (config)
    @config = config
    @verbose = config[:opts][:verbose]

    speak("Building connection to vsphere")
    @vim = RbVmomi::VIM.connect :host     => config[:host],
                               :user     => config[:user],
                               :password => config[:password],
                               :insecure => true

    p = Hash.new
    p[:vsphere] = process_all_datacenters()
    puts p.to_json
  end
  #module_function

  def speak(what)
    puts what if @verbose
  end

  def host_memory (host)
    speak("gathering memory stats for #{host.name}")
    data            = Hash.new
    data['total']   = host.hardware.memorySize.bytes.to.megabytes.to_f
    data['usage']   = host.summary.quickStats.overallMemoryUsage.megabytes.to_f
    data['percent'] = (data['usage'] / data['total']) * 100
    data
  end

  def host_cpu (host)
    speak("gathering cpu stats for #{host.name}")
    data = Hash.new
    data['Mhz']      = host.hardware.cpuInfo.hz / 1000 / 1000
    data['cores']    = host.hardware.cpuInfo.numCpuCores
    data['totalMhz'] = data['Mhz'] * data['cores']
    data['usageMhz'] = host.summary.quickStats.overallCpuUsage.to_f
    data['percent']  = (data['usageMhz'] / data['totalMhz']) * 100
    data
  end

  def host_stats (host)
    speak("gathering host stats for #{host.name}")
    data = Hash.new
    data['memory']  = host_memory(host)
    data['cpu']     = host_cpu(host)
    data
  end

  def cluster_memory (cluster)
    speak("gathering cluster memory stats for #{cluster.name}")
    data = Hash.new
    data['totalMemory']     = cluster.summary.totalMemory
    data['effectiveMemory'] = cluster.summary.effectiveMemory
    data
  end

  def cluster_cpu (cluster)
    speak("gathering cluster cpu stats for #{cluster.name}")
    data = Hash.new
    data['totalCpu']      = cluster.summary.totalCpu
    data['numCpuCores']   = cluster.summary.numCpuCores
    data['numCpuThreads'] = cluster.summary.numCpuThreads
    data['effectiveCpu']  = cluster.summary.effectiveCpu
    data
  end

  def cluster_stats (cluster)
    speak("gathering cluster stats for #{cluster.name}")
    data = Hash.new
    data['cpu']               = cluster_cpu(cluster)
    data['memory']            = cluster_memory(cluster)
    data['numVmotions']       = cluster.summary.numVmotions
    data['numHosts']          = cluster.summary.numHosts
    data['numEffectiveHosts'] = cluster.summary.numEffectiveHosts
    data['targetBalance']     = cluster.summary.targetBalance
    data['currentBalance']    = cluster.summary.currentBalance
    data
  end

  def datastore_stats (datastore)
    speak("gathering datastore stats for #{datastore.name}")
    data = Hash.new
    datastore.RefreshDatastore
    capacity = datastore.summary.capacity
    freeSpace = datastore.summary.freeSpace
    uncommitted = datastore.summary.uncommitted
    data['capacityM']    = ((capacity / 1024) / 1024) if capacity.class != NilClass
    data['freeSpaceM']   = ((freeSpace / 1024) / 1024) if freeSpace.class != NilClass
    data['uncommittedM'] = ((uncommitted / 1024) / 1024) if uncommitted.class != NilClass
    data
  end

  def network_stats (network)
    speak("gathering network stats for #{network.name}")
    data = Hash.new
    data
  end

  def process_datacenter (dc)
    speak("collecting metrics for datacenter #{dc.name}")

    data = Hash.new
    data['hypers'] = Hash.new
    data['clusters'] = Hash.new
    data['datastores'] = Hash.new
    # Get the information for host
    host_list    = dc.hostFolder.children.select {|h| h.class == RbVmomi::VIM::ComputeResource }
    host_list.map {|h|
      data['hypers'][h.name] = host_stats(h.host.first)
    }

    # Get the information for each host in a cluster
    cluster_list = dc.hostFolder.children.select {|h| h.class == RbVmomi::VIM::ClusterComputeResource }
    cluster_list.map {|c|
      data['clusters'][c.name] = cluster_stats(c)
      c.host.map {|h|
        data['hypers'][h.name] = host_stats(h)
      }
    }

    # Get informaton about datastore usage
    datastore_list = dc.datastore
    datastore_list.map {|d|
      data['datastores'][d.name] = datastore_stats(d)
    }

    data['vm_count'] = dc.vmFolder.children.select {|v| v.class == RbVmomi::VIM::VirtualMachine }.size
    data
  end

  def process_all_datacenters ()

    rootFolder = @vim.serviceInstance.content.rootFolder
    dclist = rootFolder.children.select {|d| d.class == RbVmomi::VIM::Datacenter }

    data = Hash.new
    dclist.each do |datacenter|
      data[datacenter.name] = process_datacenter(datacenter)
    end
    data

  end

end
