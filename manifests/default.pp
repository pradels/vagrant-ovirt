if $::environment == 'development' {
  $descr = 'Insight Repository - Unstable'
  $base_url = 'http://icapulp.coordinatedcareplatform.com/pulp/repos/insight_unstable/'
} else {
  $descr = 'Insight Repository - Stable'
  $base_url = 'http://icapulp.coordinatedcareplatform.com/pulp/repos/insight_stable/'
}
  
yumrepo { 'insight': 
  baseurl         => $base_url,
  descr           => $descr,
  enabled         => 1,
  gpgcheck        => 0,
  metadata_expire => 10,
}->
  
package { 'insight-hbase':
  ensure   => installed,
  provider => yum,
}
