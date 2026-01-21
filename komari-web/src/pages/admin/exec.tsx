import { useState, useRef, useEffect } from "react";
import Loading from "@/components/loading";
import { NodeDetailsProvider, useNodeDetails } from "@/contexts/NodeDetailsContext";
import { useTranslation } from "react-i18next";
import {
    Button,
    Card,
    Flex,
    Text,
    Separator,
    Badge,
    Tabs,
    Select,
    Table,
    Dialog,
    IconButton,
    TextArea
} from "@radix-ui/themes";
import { 
    Play, 
    Terminal, 
    AlertCircle, 
    CheckCircle2, 
    Copy, 
    Clock, 
    Trash2, 
    RefreshCw,
    Eye,
    History,
    Monitor,
    Server
} from "lucide-react";
import { toast } from "sonner";
import NodeSelector from "@/components/NodeSelector";
import { SettingCardCollapse } from "@/components/admin/SettingCard";

// 命令执行结果
interface CommandResult {
    id: number;
    task_id: string;
    client_uuid: string;
    client_info?: {
        uuid: string;
        name: string;
        os: string;
        [key: string]: any;
    };
    executed: boolean;
    output: string;
    exit_code: number | null;
    error_message: string;
    executed_at: string | null;
    created_at: string;
}

// 命令任务
interface CommandTask {
    id: number;
    task_id: string;
    command: string;
    target_os: string;
    target_clients: string[];
    status: string;
    created_by: string;
    total_clients: number;
    success_count: number;
    failed_count: number;
    created_at: string;
    updated_at: string;
    results?: CommandResult[];
}

// API响应格式
interface ApiResponse<T = any> {
    status: string;
    data?: T;
    message?: string;
}

const ExecPage = () => {
    return (
        <NodeDetailsProvider>
            <ExecContent />
        </NodeDetailsProvider>
    );
};

const ExecContent = () => {
    const { t } = useTranslation();
    const { nodeDetail, isLoading, error } = useNodeDetails();
    
    // 执行命令相关状态
    const [command, setCommand] = useState("");
    const [selectedNodes, setSelectedNodes] = useState<string[]>([]);
    const [targetOS, setTargetOS] = useState<string>("custom"); // "custom", "windows", "linux"
    const [executing, setExecuting] = useState(false);
    const [currentTaskId, setCurrentTaskId] = useState<string | null>(null);
    const [currentResults, setCurrentResults] = useState<CommandResult[]>([]);
    const [polling, setPolling] = useState(false);
    
    // 历史记录相关状态
    const [taskHistory, setTaskHistory] = useState<CommandTask[]>([]);
    const [historyLoading, setHistoryLoading] = useState(false);
    const [selectedTask, setSelectedTask] = useState<CommandTask | null>(null);
    const [taskDetailOpen, setTaskDetailOpen] = useState(false);
    
    // 分页状态
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize] = useState(10);
    const [totalTasks, setTotalTasks] = useState(0);

    // 使用 useRef 来保存轮询相关的引用
    const pollingIntervalRef = useRef<NodeJS.Timeout | null>(null);
    const pollingTimeoutRef = useRef<NodeJS.Timeout | null>(null);

    // 清理轮询的函数
    const clearPolling = () => {
        if (pollingIntervalRef.current) {
            clearInterval(pollingIntervalRef.current);
            pollingIntervalRef.current = null;
        }
        if (pollingTimeoutRef.current) {
            clearTimeout(pollingTimeoutRef.current);
            pollingTimeoutRef.current = null;
        }
        setPolling(false);
    };

    // 组件卸载时清理轮询
    useEffect(() => {
        return () => {
            clearPolling();
        };
    }, []);
    
    // 加载任务历史
    useEffect(() => {
        loadTaskHistory();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [currentPage]);

    if (isLoading) {
        return <Loading />;
    }

    if (error) {
        return <div className="text-red-500">{error}</div>;
    }

    // 加载任务历史列表
    const loadTaskHistory = async () => {
        setHistoryLoading(true);
        try {
            const response = await fetch(
                `/api/admin/command/list?page=${currentPage}&page_size=${pageSize}`
            );
            if (!response.ok) throw new Error("Failed to load task history");
            
            const data: ApiResponse<{ tasks: CommandTask[]; total: number }> = await response.json();
            if (data.status === "success" && data.data) {
                setTaskHistory(data.data.tasks || []);
                setTotalTasks(data.data.total || 0);
            }
        } catch (err) {
            console.error("Failed to load task history:", err);
            toast.error("加载任务历史失败");
        } finally {
            setHistoryLoading(false);
        }
    };
    
    // 轮询任务结果（使用新API）
    const pollTaskResult = async (taskId: string) => {
        try {
            const response = await fetch(`/api/admin/command/${taskId}`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data: ApiResponse<CommandTask> = await response.json();
            
            if (data.status === "success" && data.data) {
                const task = data.data;
                setCurrentResults(task.results || []);

                // 检查是否所有任务都已完成
                if (task.status === "completed") {
                    clearPolling();
                    toast.success(`任务执行完成 - 成功: ${task.success_count}, 失败: ${task.failed_count}`);
                    loadTaskHistory(); // 刷新历史记录
                }
            }
        } catch (err) {
            console.error("轮询任务结果失败:", err);
            clearPolling();
        }
    };

    // 开始轮询
    const startPolling = (taskId: string) => {
        // 先清理之前的轮询
        clearPolling();

        setPolling(true);

        // 首次立即执行
        pollTaskResult(taskId);

        // 设置定时轮询
        pollingIntervalRef.current = setInterval(() => {
            pollTaskResult(taskId);
        }, 2000);

        // 60秒后停止轮询
        pollingTimeoutRef.current = setTimeout(() => {
            clearPolling();
            toast.warning("任务执行超时，请刷新查看最新状态");
        }, 60000);
    };

    // 执行命令（使用新API）
    const executeCommand = async () => {
        if (!command.trim()) {
            toast.error("请输入命令");
            return;
        }

        // 批量执行或指定节点执行
        if (targetOS === "custom" && selectedNodes.length === 0) {
            toast.error("请选择目标节点或操作系统");
            return;
        }

        // 清理之前的轮询
        clearPolling();

        setExecuting(true);
        setCurrentResults([]);
        setCurrentTaskId(null);

        try {
            const requestBody: any = {
                command: command.trim(),
            };
            
            // 如果指定了操作系统，按OS批量执行
            if (targetOS) {
                requestBody.target_os = targetOS;
            } else if (selectedNodes.length > 0) {
                // 否则按选中的节点执行
                requestBody.target_clients = selectedNodes;
            }

            const response = await fetch("/api/admin/command/create", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(requestBody),
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
            }

            const data: ApiResponse<{ task_id: string; total_clients: number }> = await response.json();

            if (data.status === "success" && data.data?.task_id) {
                setCurrentTaskId(data.data.task_id);
                toast.success(`任务已下发到 ${data.data.total_clients} 个客户端`);
                startPolling(data.data.task_id);
            } else {
                throw new Error(data.message || "创建任务失败");
            }
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : "未知错误";
            toast.error(errorMessage);
        } finally {
            setExecuting(false);
        }
    };
    
    // 查看任务详情
    const viewTaskDetail = async (taskId: string) => {
        try {
            const response = await fetch(`/api/admin/command/${taskId}`);
            if (!response.ok) throw new Error("Failed to load task detail");
            
            const data: ApiResponse<CommandTask> = await response.json();
            if (data.status === "success" && data.data) {
                setSelectedTask(data.data);
                setTaskDetailOpen(true);
            }
        } catch (err) {
            console.error("Failed to load task detail:", err);
            toast.error("加载任务详情失败");
        }
    };
    
    // 删除任务
    const deleteTask = async (taskId: string) => {
        if (!confirm("确定要删除这个任务吗？")) return;
        
        try {
            const response = await fetch(`/api/admin/command/${taskId}`, {
                method: "DELETE",
            });
            if (!response.ok) throw new Error("Failed to delete task");
            
            toast.success("任务已删除");
            loadTaskHistory();
        } catch (err) {
            console.error("Failed to delete task:", err);
            toast.error("删除任务失败");
        }
    };

    const copyOutput = (output: string) => {
        navigator.clipboard.writeText(output);
        toast.success(t("common.success"));
    };

    const getSelectedNodeNames = () => {
        return selectedNodes.map(uuid => {
            const node = nodeDetail.find(n => n.uuid === uuid);
            return node ? node.name : uuid;
        }).join(", ");
    };

    const getTaskStatus = (task: CommandTask) => {
        if (task.status === "running") {
            return { color: "blue" as const, text: "执行中" };
        }
        if (task.status === "completed") {
            return { color: "green" as const, text: "已完成" };
        }
        if (task.status === "failed") {
            return { color: "red" as const, text: "失败" };
        }
        return { color: "gray" as const, text: task.status };
    };
    
    const getResultStatus = (result: CommandResult) => {
        if (!result.executed) {
            return { status: "pending", color: "gray" as const, text: "待执行" };
        }
        if (result.exit_code === 0) {
            return { status: "success", color: "green" as const, text: "成功" };
        }
        return { status: "failed", color: "red" as const, text: "失败" };
    };

    return (
        <div className="p-4 flex flex-col gap-3">
            <div>
                <h1 className="text-2xl font-bold">远程命令执行</h1>
                <Text size="2" color="gray" className="mt-1">
                    向客户端下发系统命令并查看执行结果
                </Text>
            </div>

            <Separator size="4" />

            <Tabs.Root defaultValue="execute">
                <Tabs.List>
                    <Tabs.Trigger value="execute">
                        <Terminal size={16} />
                        执行命令
                    </Tabs.Trigger>
                    <Tabs.Trigger value="history">
                        <History size={16} />
                        执行历史
                    </Tabs.Trigger>
                </Tabs.List>

                <Tabs.Content value="execute">
                    <Card className="p-6 mt-4">
                        <Flex direction="column" gap="4">
                            <label className="text-xl font-bold">命令</label>
                            <TextArea
                                value={command}
                                onChange={(e) => setCommand(e.target.value)}
                                placeholder="输入要执行的命令，例如: echo hello world"
                                size="3"
                                rows={3}
                            />

                            <Flex direction="column" gap="2">
                                <label className="text-lg font-medium">执行目标</label>
                                <Select.Root value={targetOS} onValueChange={setTargetOS}>
                                    <Select.Trigger placeholder="选择批量执行目标或自定义选择节点" />
                                    <Select.Content>
                                        <Select.Item value="custom">
                                            自定义选择节点
                                        </Select.Item>
                                        <Select.Item value="windows">
                                            <Flex align="center" gap="2">
                                                <Monitor size={14} />
                                                所有 Windows 客户端
                                            </Flex>
                                        </Select.Item>
                                        <Select.Item value="linux">
                                            <Flex align="center" gap="2">
                                                <Server size={14} />
                                                所有 Linux 客户端
                                            </Flex>
                                        </Select.Item>
                                    </Select.Content>
                                </Select.Root>
                            </Flex>

                            {targetOS === "custom" && (
                                <div>
                                    <SettingCardCollapse title="选择节点" defaultOpen>
                                        <NodeSelector
                                            value={selectedNodes}
                                            onChange={setSelectedNodes}
                                            className="min-h-[200px]"
                                        />
                                    </SettingCardCollapse>
                                    {selectedNodes.length > 0 && (
                                        <Text size="2" color="gray" className="mt-2">
                                            已选择节点: {getSelectedNodeNames()}
                                        </Text>
                                    )}
                                </div>
                            )}

                            {targetOS && (
                                <Card className="p-3 bg-blue-50 dark:bg-blue-950">
                                    <Flex align="center" gap="2">
                                        <AlertCircle size={16} className="text-blue-600" />
                                        <Text size="2" color="blue">
                                            将在所有在线的 <strong>{targetOS === "windows" ? "Windows" : "Linux"}</strong> 客户端上执行此命令
                                        </Text>
                                    </Flex>
                                </Card>
                            )}

                            <Flex justify="end" gap="2">
                                <Button
                                    onClick={executeCommand}
                                    disabled={executing || !command.trim() || (targetOS === "custom" && selectedNodes.length === 0)}
                                >
                                    {executing ? (
                                        <>
                                            <div className="animate-spin rounded-full h-4 w-4 border-2 border-current border-t-transparent" />
                                            执行中...
                                        </>
                                    ) : (
                                        <>
                                            <Play size={16} />
                                            执行命令
                                        </>
                                    )}
                                </Button>
                            </Flex>
                        </Flex>
                    </Card>

                    {currentResults.length > 0 && (
                        <Card className="p-6 mt-4">
                            <Flex direction="column" gap="4">
                                <Flex justify="between" align="center">
                                    <Text size="4" weight="medium">执行结果</Text>
                                    {currentTaskId && (
                                        <Text size="2" color="gray">任务ID: {currentTaskId}</Text>
                                    )}
                                </Flex>

                                <div className="space-y-3">
                                    {currentResults.map((result) => {
                                        const status = getResultStatus(result);
                                        return (
                                            <Card key={result.id} className="p-4">
                                                <Flex direction="column" gap="3">
                                                    <Flex justify="between" align="center">
                                                        <Flex align="center" gap="2">
                                                            <Text weight="medium">
                                                                {result.client_info?.name || result.client_uuid}
                                                            </Text>
                                                            <Badge color={status.color} variant="soft">
                                                                {status.status === "success" ? (
                                                                    <><CheckCircle2 size={12} /> {status.text}</>
                                                                ) : status.status === "failed" ? (
                                                                    <><AlertCircle size={12} /> {status.text}</>
                                                                ) : (
                                                                    <><Clock size={12} /> {status.text}</>
                                                                )}
                                                            </Badge>
                                                            {result.exit_code !== null && (
                                                                <Text size="1" color="gray">
                                                                    退出码: {result.exit_code}
                                                                </Text>
                                                            )}
                                                        </Flex>
                                                        {result.output && (
                                                            <Button
                                                                variant="ghost"
                                                                size="1"
                                                                onClick={() => copyOutput(result.output)}
                                                            >
                                                                <Copy size={14} />
                                                            </Button>
                                                        )}
                                                    </Flex>

                                                    {result.output && (
                                                        <div className="bg-[var(--gray-2)] rounded-md p-3 font-mono text-sm overflow-x-auto">
                                                            <pre className="whitespace-pre-wrap">{result.output}</pre>
                                                        </div>
                                                    )}
                                                    
                                                    {result.error_message && (
                                                        <Card className="p-2 bg-red-50 dark:bg-red-950">
                                                            <Text size="2" color="red">{result.error_message}</Text>
                                                        </Card>
                                                    )}
                                                </Flex>
                                            </Card>
                                        );
                                    })}
                                </div>

                                {polling && (
                                    <Flex align="center" justify="between">
                                        <Flex align="center" gap="2">
                                            <div className="animate-spin rounded-full h-4 w-4 border-2 border-current border-t-transparent" />
                                            <Text size="2" color="gray">正在获取最新执行状态...</Text>
                                        </Flex>
                                        <Button variant="soft" size="1" onClick={clearPolling}>
                                            停止轮询
                                        </Button>
                                    </Flex>
                                )}
                            </Flex>
                        </Card>
                    )}
                </Tabs.Content>

                <Tabs.Content value="history">
                    <Card className="p-6 mt-4">
                        <Flex direction="column" gap="4">
                            <Flex justify="between" align="center">
                                <Text size="4" weight="medium">命令执行历史</Text>
                                <Button size="2" variant="soft" onClick={loadTaskHistory}>
                                    <RefreshCw size={16} />
                                    刷新
                                </Button>
                            </Flex>

                            {historyLoading ? (
                                <Loading />
                            ) : taskHistory.length === 0 ? (
                                <Card className="p-8">
                                    <Flex direction="column" align="center" gap="2">
                                        <History size={48} className="text-gray-400" />
                                        <Text color="gray">暂无执行历史</Text>
                                    </Flex>
                                </Card>
                            ) : (
                                <Table.Root variant="surface">
                                    <Table.Header>
                                        <Table.Row>
                                            <Table.ColumnHeaderCell>任务ID</Table.ColumnHeaderCell>
                                            <Table.ColumnHeaderCell>命令</Table.ColumnHeaderCell>
                                            <Table.ColumnHeaderCell>目标</Table.ColumnHeaderCell>
                                            <Table.ColumnHeaderCell>状态</Table.ColumnHeaderCell>
                                            <Table.ColumnHeaderCell>统计</Table.ColumnHeaderCell>
                                            <Table.ColumnHeaderCell>创建时间</Table.ColumnHeaderCell>
                                            <Table.ColumnHeaderCell>操作</Table.ColumnHeaderCell>
                                        </Table.Row>
                                    </Table.Header>
                                    <Table.Body>
                                        {taskHistory.map((task) => {
                                            const status = getTaskStatus(task);
                                            return (
                                                <Table.Row key={task.task_id}>
                                                    <Table.Cell>
                                                        <Text size="1" className="font-mono">
                                                            {task.task_id.substring(0, 8)}...
                                                        </Text>
                                                    </Table.Cell>
                                                    <Table.Cell>
                                                        <Text className="max-w-xs truncate block">
                                                            {task.command}
                                                        </Text>
                                                    </Table.Cell>
                                                    <Table.Cell>
                                                        {task.target_os ? (
                                                            <Badge variant="soft">
                                                                {task.target_os === "windows" ? (
                                                                    <><Monitor size={12} /> Windows</>
                                                                ) : (
                                                                    <><Server size={12} /> Linux</>
                                                                )}
                                                            </Badge>
                                                        ) : (
                                                            <Text size="2" color="gray">
                                                                {task.total_clients} 个节点
                                                            </Text>
                                                        )}
                                                    </Table.Cell>
                                                    <Table.Cell>
                                                        <Badge color={status.color} variant="soft">
                                                            {status.text}
                                                        </Badge>
                                                    </Table.Cell>
                                                    <Table.Cell>
                                                        <Flex gap="2">
                                                            <Badge color="green" variant="soft">
                                                                成功: {task.success_count}
                                                            </Badge>
                                                            {task.failed_count > 0 && (
                                                                <Badge color="red" variant="soft">
                                                                    失败: {task.failed_count}
                                                                </Badge>
                                                            )}
                                                        </Flex>
                                                    </Table.Cell>
                                                    <Table.Cell>
                                                        <Text size="2" color="gray">
                                                            {new Date(task.created_at).toLocaleString()}
                                                        </Text>
                                                    </Table.Cell>
                                                    <Table.Cell>
                                                        <Flex gap="1">
                                                            <IconButton
                                                                size="1"
                                                                variant="ghost"
                                                                onClick={() => viewTaskDetail(task.task_id)}
                                                            >
                                                                <Eye size={14} />
                                                            </IconButton>
                                                            <IconButton
                                                                size="1"
                                                                variant="ghost"
                                                                color="red"
                                                                onClick={() => deleteTask(task.task_id)}
                                                            >
                                                                <Trash2 size={14} />
                                                            </IconButton>
                                                        </Flex>
                                                    </Table.Cell>
                                                </Table.Row>
                                            );
                                        })}
                                    </Table.Body>
                                </Table.Root>
                            )}

                            {totalTasks > pageSize && (
                                <Flex justify="center" gap="2">
                                    <Button
                                        size="1"
                                        variant="soft"
                                        disabled={currentPage === 1}
                                        onClick={() => setCurrentPage(currentPage - 1)}
                                    >
                                        上一页
                                    </Button>
                                    <Text size="2" className="self-center">
                                        第 {currentPage} 页 / 共 {Math.ceil(totalTasks / pageSize)} 页
                                    </Text>
                                    <Button
                                        size="1"
                                        variant="soft"
                                        disabled={currentPage >= Math.ceil(totalTasks / pageSize)}
                                        onClick={() => setCurrentPage(currentPage + 1)}
                                    >
                                        下一页
                                    </Button>
                                </Flex>
                            )}
                        </Flex>
                    </Card>
                </Tabs.Content>
            </Tabs.Root>

            <Dialog.Root open={taskDetailOpen} onOpenChange={setTaskDetailOpen}>
                <Dialog.Content maxWidth="800px">
                    <Dialog.Title>任务详情</Dialog.Title>
                    {selectedTask && (
                        <Flex direction="column" gap="4">
                            <Flex direction="column" gap="2">
                                <Text size="2" weight="bold">任务ID</Text>
                                <Text className="font-mono">{selectedTask.task_id}</Text>
                            </Flex>
                            
                            <Flex direction="column" gap="2">
                                <Text size="2" weight="bold">命令</Text>
                                <Card className="p-3 bg-[var(--gray-2)]">
                                    <pre className="font-mono text-sm">{selectedTask.command}</pre>
                                </Card>
                            </Flex>

                            <Flex gap="4">
                                <Flex direction="column" gap="1">
                                    <Text size="2" weight="bold">状态</Text>
                                    <Badge color={getTaskStatus(selectedTask).color}>
                                        {getTaskStatus(selectedTask).text}
                                    </Badge>
                                </Flex>
                                <Flex direction="column" gap="1">
                                    <Text size="2" weight="bold">总客户端</Text>
                                    <Text>{selectedTask.total_clients}</Text>
                                </Flex>
                                <Flex direction="column" gap="1">
                                    <Text size="2" weight="bold">成功</Text>
                                    <Text color="green">{selectedTask.success_count}</Text>
                                </Flex>
                                <Flex direction="column" gap="1">
                                    <Text size="2" weight="bold">失败</Text>
                                    <Text color="red">{selectedTask.failed_count}</Text>
                                </Flex>
                            </Flex>

                            {selectedTask.results && selectedTask.results.length > 0 && (
                                <Flex direction="column" gap="2">
                                    <Text size="2" weight="bold">执行结果</Text>
                                    <div className="max-h-96 overflow-y-auto space-y-2">
                                        {selectedTask.results.map((result) => {
                                            const status = getResultStatus(result);
                                            return (
                                                <Card key={result.id} className="p-3">
                                                    <Flex direction="column" gap="2">
                                                        <Flex justify="between" align="center">
                                                            <Text weight="medium">
                                                                {result.client_info?.name || result.client_uuid}
                                                            </Text>
                                                            <Badge color={status.color} variant="soft">
                                                                {status.text}
                                                            </Badge>
                                                        </Flex>
                                                        {result.output && (
                                                            <div className="bg-[var(--gray-2)] rounded p-2 font-mono text-xs">
                                                                <pre className="whitespace-pre-wrap max-h-32 overflow-y-auto">
                                                                    {result.output}
                                                                </pre>
                                                            </div>
                                                        )}
                                                    </Flex>
                                                </Card>
                                            );
                                        })}
                                    </div>
                                </Flex>
                            )}

                            <Flex justify="end" gap="2">
                                <Dialog.Close>
                                    <Button variant="soft">关闭</Button>
                                </Dialog.Close>
                            </Flex>
                        </Flex>
                    )}
                </Dialog.Content>
            </Dialog.Root>
        </div>
    );
};

export default ExecPage;
