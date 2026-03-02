import React, { useState, useEffect } from "react";
import { toast } from "sonner";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from "@/components/ui/table";
import { useTranslation } from "react-i18next";
import { Dialog, Flex, Button, TextField, Select, Switch, Text, Badge } from "@radix-ui/themes";
import Loading from "@/components/loading";
import { PlusIcon, Trash2Icon, EditIcon, ActivityIcon, TestTubeIcon } from "lucide-react";

interface NetworkDevice {
  id: number;
  name: string;
  host: string;
  port: number;
  snmp_version: string;
  community?: string;
  security_level?: string;
  auth_username?: string;
  auth_password?: string;
  auth_protocol?: string;
  privacy_password?: string;
  privacy_protocol?: string;
  description: string;
  group: string;
  tags: string;
  enabled: boolean;
  collect_interval: number;
  created_at: string;
  updated_at: string;
}

interface NetworkDeviceMetrics {
  system_desc: string;
  system_uptime: number;
  cpu_load_5min: number;
  cpu_usage: number;
  mem_total: number;
  mem_available: number;
  mem_usage_percent: number;
  disk_info: string;
  net_in_bytes: number;
  net_out_bytes: number;
  interface_info: string;
  collected_at: string;
}

export default function NetworkDevices() {
  const [t] = useTranslation();
  const [devices, setDevices] = useState<NetworkDevice[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [metricsDialogOpen, setMetricsDialogOpen] = useState(false);
  const [editingDevice, setEditingDevice] = useState<NetworkDevice | null>(null);
  const [currentMetrics, setCurrentMetrics] = useState<NetworkDeviceMetrics | null>(null);

  // 表单状态
  const [formData, setFormData] = useState<Partial<NetworkDevice>>({
    name: "",
    host: "",
    port: 161,
    snmp_version: "v2c",
    community: "public",
    enabled: true,
    collect_interval: 60,
    description: "",
    group: "",
    tags: "",
  });

  useEffect(() => {
    fetchDevices();
  }, []);

  const fetchDevices = async () => {
    try {
      const response = await fetch("/api/admin/network-device");
      const data = await response.json();
      if (data.success) {
        setDevices(data.data || []);
      } else {
        toast.error("获取设备列表失败");
      }
    } catch (error) {
      toast.error("网络错误");
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = () => {
    setEditingDevice(null);
    setFormData({
      name: "",
      host: "",
      port: 161,
      snmp_version: "v2c",
      community: "public",
      enabled: true,
      collect_interval: 60,
      description: "",
      group: "",
      tags: "",
    });
    setDialogOpen(true);
  };

  const handleEdit = (device: NetworkDevice) => {
    setEditingDevice(device);
    setFormData(device);
    setDialogOpen(true);
  };

  const handleSave = async () => {
    try {
      const url = editingDevice
        ? `/api/admin/network-device/${editingDevice.id}`
        : "/api/admin/network-device";
      const method = editingDevice ? "PUT" : "POST";

      const response = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      const data = await response.json();
      if (data.success) {
        toast.success(editingDevice ? "更新成功" : "创建成功");
        setDialogOpen(false);
        fetchDevices();
      } else {
        toast.error(data.message || "操作失败");
      }
    } catch (error) {
      toast.error("网络错误");
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("确定要删除这个设备吗？")) return;

    try {
      const response = await fetch(`/api/admin/network-device/${id}`, {
        method: "DELETE",
      });
      const data = await response.json();
      if (data.success) {
        toast.success("删除成功");
        fetchDevices();
      } else {
        toast.error("删除失败");
      }
    } catch (error) {
      toast.error("网络错误");
    }
  };

  const handleTestConnection = async () => {
    try {
      const response = await fetch("/api/admin/network-device/test", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });
      const data = await response.json();
      if (data.success) {
        toast.success("连接测试成功");
      } else {
        toast.error(data.message || "连接测试失败");
      }
    } catch (error) {
      toast.error("网络错误");
    }
  };

  const handleCollect = async (device: NetworkDevice) => {
    try {
      toast.info("正在采集数据...");
      const response = await fetch(`/api/admin/network-device/${device.id}/collect`, {
        method: "POST",
      });
      const data = await response.json();
      if (data.success) {
        toast.success("数据采集成功");
        setCurrentMetrics(data.data);
        setMetricsDialogOpen(true);
      } else {
        toast.error(data.message || "采集失败");
      }
    } catch (error) {
      toast.error("网络错误");
    }
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${days}天 ${hours}小时 ${minutes}分钟`;
  };

  if (loading) {
    return <Loading />;
  }

  return (
    <div className="p-4">
      <Flex justify="between" align="center" className="mb-4">
        <h1 className="text-2xl font-semibold">网络设备管理</h1>
        <Button onClick={handleCreate}>
          <PlusIcon className="w-4 h-4 mr-2" />
          添加设备
        </Button>
      </Flex>

      <div className="overflow-hidden rounded-lg">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>设备名称</TableHead>
              <TableHead>主机地址</TableHead>
              <TableHead>SNMP版本</TableHead>
              <TableHead>状态</TableHead>
              <TableHead>分组</TableHead>
              <TableHead>采集间隔</TableHead>
              <TableHead>操作</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {devices.map((device) => (
              <TableRow key={device.id}>
                <TableCell className="font-medium">{device.name}</TableCell>
                <TableCell>{device.host}:{device.port}</TableCell>
                <TableCell>
                  <Badge>{device.snmp_version.toUpperCase()}</Badge>
                </TableCell>
                <TableCell>
                  {device.enabled ? (
                    <Badge color="green">启用</Badge>
                  ) : (
                    <Badge color="gray">禁用</Badge>
                  )}
                </TableCell>
                <TableCell>{device.group || "-"}</TableCell>
                <TableCell>{device.collect_interval}秒</TableCell>
                <TableCell>
                  <Flex gap="2">
                    <Button
                      size="1"
                      variant="soft"
                      onClick={() => handleCollect(device)}
                      title="手动采集"
                    >
                      <ActivityIcon className="w-4 h-4" />
                    </Button>
                    <Button
                      size="1"
                      variant="soft"
                      onClick={() => handleEdit(device)}
                      title="编辑"
                    >
                      <EditIcon className="w-4 h-4" />
                    </Button>
                    <Button
                      size="1"
                      variant="soft"
                      color="red"
                      onClick={() => handleDelete(device.id)}
                      title="删除"
                    >
                      <Trash2Icon className="w-4 h-4" />
                    </Button>
                  </Flex>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {/* 添加/编辑设备对话框 */}
      <Dialog.Root open={dialogOpen} onOpenChange={setDialogOpen}>
        <Dialog.Content style={{ maxWidth: 600 }}>
          <Dialog.Title>
            {editingDevice ? "编辑设备" : "添加设备"}
          </Dialog.Title>

          <Flex direction="column" gap="3" className="mt-4">
            <label>
              <Text as="div" size="2" mb="1" weight="bold">
                设备名称 *
              </Text>
              <TextField.Root
                value={formData.name || ""}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="例如: 核心交换机"
              />
            </label>

            <Flex gap="3">
              <label style={{ flex: 1 }}>
                <Text as="div" size="2" mb="1" weight="bold">
                  主机地址 *
                </Text>
                <TextField.Root
                  value={formData.host || ""}
                  onChange={(e) => setFormData({ ...formData, host: e.target.value })}
                  placeholder="IP 或主机名"
                />
              </label>

              <label style={{ flex: 0.3 }}>
                <Text as="div" size="2" mb="1" weight="bold">
                  端口
                </Text>
                <TextField.Root
                  type="number"
                  value={formData.port || 161}
                  onChange={(e) => setFormData({ ...formData, port: parseInt(e.target.value) })}
                />
              </label>
            </Flex>

            <label>
              <Text as="div" size="2" mb="1" weight="bold">
                SNMP 版本 *
              </Text>
              <Select.Root
                value={formData.snmp_version || "v2c"}
                onValueChange={(value) => setFormData({ ...formData, snmp_version: value })}
              >
                <Select.Trigger />
                <Select.Content>
                  <Select.Item value="v1">SNMP v1</Select.Item>
                  <Select.Item value="v2c">SNMP v2c</Select.Item>
                  <Select.Item value="v3">SNMP v3</Select.Item>
                </Select.Content>
              </Select.Root>
            </label>

            {(formData.snmp_version === "v1" || formData.snmp_version === "v2c") && (
              <label>
                <Text as="div" size="2" mb="1" weight="bold">
                  Community String
                </Text>
                <TextField.Root
                  value={formData.community || ""}
                  onChange={(e) => setFormData({ ...formData, community: e.target.value })}
                  placeholder="public"
                />
              </label>
            )}

            {formData.snmp_version === "v3" && (
              <>
                <label>
                  <Text as="div" size="2" mb="1" weight="bold">
                    安全级别
                  </Text>
                  <Select.Root
                    value={formData.security_level || "noAuthNoPriv"}
                    onValueChange={(value) => setFormData({ ...formData, security_level: value })}
                  >
                    <Select.Trigger />
                    <Select.Content>
                      <Select.Item value="noAuthNoPriv">NoAuthNoPriv</Select.Item>
                      <Select.Item value="authNoPriv">AuthNoPriv</Select.Item>
                      <Select.Item value="authPriv">AuthPriv</Select.Item>
                    </Select.Content>
                  </Select.Root>
                </label>

                <label>
                  <Text as="div" size="2" mb="1" weight="bold">
                    用户名
                  </Text>
                  <TextField.Root
                    value={formData.auth_username || ""}
                    onChange={(e) => setFormData({ ...formData, auth_username: e.target.value })}
                  />
                </label>

                {formData.security_level !== "noAuthNoPriv" && (
                  <>
                    <Flex gap="3">
                      <label style={{ flex: 1 }}>
                        <Text as="div" size="2" mb="1" weight="bold">
                          认证协议
                        </Text>
                        <Select.Root
                          value={formData.auth_protocol || "MD5"}
                          onValueChange={(value) => setFormData({ ...formData, auth_protocol: value })}
                        >
                          <Select.Trigger />
                          <Select.Content>
                            <Select.Item value="MD5">MD5</Select.Item>
                            <Select.Item value="SHA">SHA</Select.Item>
                          </Select.Content>
                        </Select.Root>
                      </label>

                      <label style={{ flex: 1 }}>
                        <Text as="div" size="2" mb="1" weight="bold">
                          认证密码
                        </Text>
                        <TextField.Root
                          type="password"
                          value={formData.auth_password || ""}
                          onChange={(e) => setFormData({ ...formData, auth_password: e.target.value })}
                        />
                      </label>
                    </Flex>
                  </>
                )}

                {formData.security_level === "authPriv" && (
                  <Flex gap="3">
                    <label style={{ flex: 1 }}>
                      <Text as="div" size="2" mb="1" weight="bold">
                        加密协议
                      </Text>
                      <Select.Root
                        value={formData.privacy_protocol || "DES"}
                        onValueChange={(value) => setFormData({ ...formData, privacy_protocol: value })}
                      >
                        <Select.Trigger />
                        <Select.Content>
                          <Select.Item value="DES">DES</Select.Item>
                          <Select.Item value="AES">AES</Select.Item>
                        </Select.Content>
                      </Select.Root>
                    </label>

                    <label style={{ flex: 1 }}>
                      <Text as="div" size="2" mb="1" weight="bold">
                        加密密码
                      </Text>
                      <TextField.Root
                        type="password"
                        value={formData.privacy_password || ""}
                        onChange={(e) => setFormData({ ...formData, privacy_password: e.target.value })}
                      />
                    </label>
                  </Flex>
                )}
              </>
            )}

            <Flex gap="3">
              <label style={{ flex: 1 }}>
                <Text as="div" size="2" mb="1" weight="bold">
                  分组
                </Text>
                <TextField.Root
                  value={formData.group || ""}
                  onChange={(e) => setFormData({ ...formData, group: e.target.value })}
                  placeholder="例如: 核心网络"
                />
              </label>

              <label style={{ flex: 1 }}>
                <Text as="div" size="2" mb="1" weight="bold">
                  采集间隔 (秒)
                </Text>
                <TextField.Root
                  type="number"
                  value={formData.collect_interval || 60}
                  onChange={(e) => setFormData({ ...formData, collect_interval: parseInt(e.target.value) })}
                />
              </label>
            </Flex>

            <label>
              <Text as="div" size="2" mb="1" weight="bold">
                描述
              </Text>
              <TextField.Root
                value={formData.description || ""}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="设备描述"
              />
            </label>

            <label>
              <Flex gap="2" align="center">
                <Switch
                  checked={formData.enabled}
                  onCheckedChange={(checked) => setFormData({ ...formData, enabled: checked })}
                />
                <Text>启用设备</Text>
              </Flex>
            </label>
          </Flex>

          <Flex gap="3" mt="4" justify="end">
            <Button variant="soft" onClick={handleTestConnection}>
              <TestTubeIcon className="w-4 h-4 mr-2" />
              测试连接
            </Button>
            <Dialog.Close>
              <Button variant="soft" color="gray">
                取消
              </Button>
            </Dialog.Close>
            <Button onClick={handleSave}>
              保存
            </Button>
          </Flex>
        </Dialog.Content>
      </Dialog.Root>

      {/* 监控数据对话框 */}
      <Dialog.Root open={metricsDialogOpen} onOpenChange={setMetricsDialogOpen}>
        <Dialog.Content style={{ maxWidth: 800 }}>
          <Dialog.Title>设备监控数据</Dialog.Title>

          {currentMetrics && (
            <Flex direction="column" gap="3" className="mt-4">
              <div>
                <Text weight="bold">系统信息</Text>
                <div className="mt-2 p-3 bg-gray-100 rounded">
                  <Text size="2">{currentMetrics.system_desc}</Text>
                </div>
              </div>

              <Flex gap="3">
                <div style={{ flex: 1 }}>
                  <Text weight="bold">运行时间</Text>
                  <Text size="2" className="mt-1">
                    {formatUptime(currentMetrics.system_uptime)}
                  </Text>
                </div>
                <div style={{ flex: 1 }}>
                  <Text weight="bold">CPU 负载 (5分钟)</Text>
                  <Text size="2" className="mt-1">
                    {currentMetrics.cpu_load_5min.toFixed(2)}
                  </Text>
                </div>
              </Flex>

              <div>
                <Text weight="bold">内存使用</Text>
                <div className="mt-2">
                  <Text size="2">
                    总内存: {formatBytes(currentMetrics.mem_total)}
                  </Text>
                  <br />
                  <Text size="2">
                    可用内存: {formatBytes(currentMetrics.mem_available)}
                  </Text>
                  <br />
                  <Text size="2">
                    使用率: {currentMetrics.mem_usage_percent.toFixed(2)}%
                  </Text>
                </div>
              </div>

              <div>
                <Text weight="bold">网络流量</Text>
                <div className="mt-2">
                  <Text size="2">
                    入站: {formatBytes(currentMetrics.net_in_bytes)}
                  </Text>
                  <br />
                  <Text size="2">
                    出站: {formatBytes(currentMetrics.net_out_bytes)}
                  </Text>
                </div>
              </div>

              <div>
                <Text weight="bold" size="2" className="text-gray-500">
                  采集时间: {new Date(currentMetrics.collected_at).toLocaleString()}
                </Text>
              </div>
            </Flex>
          )}

          <Flex gap="3" mt="4" justify="end">
            <Dialog.Close>
              <Button variant="soft">关闭</Button>
            </Dialog.Close>
          </Flex>
        </Dialog.Content>
      </Dialog.Root>
    </div>
  );
}
